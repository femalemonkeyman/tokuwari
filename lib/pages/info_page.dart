import 'package:async/async.dart';
import 'package:expand_widget/expand_widget.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:tokuwari/models/anidata.dart';
import 'package:tokuwari/models/media_prov.dart';
import 'package:tokuwari/widgets/media_tags.dart';
import '../media/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import '../widgets/image.dart';

extension on Widget {
  Widget padBottom() {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: this);
  }
}

class InfoPage extends StatelessWidget {
  final AniData data;

  const InfoPage({super.key, required this.data});

  @override
  Widget build(context) {
    return Scaffold(
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {},
      //   label: const Text('Continue?'),
      // ),
      body: SafeArea(
        child: CustomScrollView(
          primary: true,
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(data.title),
              actions: [
                LaterButton(
                  data: data,
                ),
                PopupMenuButton(
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        child: Text('Placeholder'),
                      ),
                    ];
                  },
                )
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.only(
                left: 15,
                right: 15,
                top: 10,
                bottom: 10,
              ),
              sliver: SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, con) {
                    if (con.maxWidth > 600) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: InfoView(data),
                          ),
                          Flexible(
                            child: Selector(data: data),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          InfoView(data),
                          Selector(data: data),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoView extends StatelessWidget {
  final AniData data;

  const InfoView(this.data, {super.key});

  @override
  Widget build(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 100,
              ),
              child: AniImage(
                image: data.image,
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Flexible(
              child: Text.rich(
                TextSpan(
                  text: data.title,
                  children: [
                    TextSpan(
                      text: '\n${data.status}\nScore: ${data.score}\nCount: ${data.count}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ).padBottom(),
        Flexible(
          child: ExpandText(
            data.description,
            textAlign: TextAlign.start,
            maxLines: 3,
          ).padBottom(),
        ),
        Flexible(
          child: MediaTags(data).padBottom(),
        ),
      ],
    );
  }
}

class LaterButton extends StatefulWidget {
  final Isar isar = Isar.get(schemas: [AniDataSchema], name: 'tokudb');
  final AniData data;

  LaterButton({super.key, required this.data});

  @override
  State createState() => LaterButtonState();
}

class LaterButtonState extends State<LaterButton> {
  late final media = widget.isar.aniDatas.where().mediaIdEqualTo(widget.data.mediaId);

  @override
  Widget build(context) {
    return IconButton(
      onPressed: () => setState(
        () {
          if (media.isEmpty()) {
            widget.data.id = widget.isar.aniDatas.autoIncrement();
            widget.isar.write(
              (isar) => widget.isar.aniDatas.put(widget.data),
            );
          } else {
            widget.isar.write(
              (isar) => media.deleteAll(),
            );
          }
        },
      ),
      icon: (media.isEmpty()) ? const Icon(Icons.bookmark_add_outlined) : const Icon(Icons.bookmark_added_rounded),
    );
  }
}

class Selector extends StatefulWidget {
  final AniData data;

  const Selector({
    super.key,
    required this.data,
  });

  @override
  State<Selector> createState() => SelectorState();
}

class SelectorState extends State<Selector> {
  late Map<String, dynamic> provider;
  late CancelableOperation<List<MediaProv>> load;
  final con = PageController();
  late final String episodeLabel = widget.data.type == 'anime' ? 'Episode:' : 'Chapter:';

  @override
  void initState() {
    super.initState();
    provider = providers[widget.data.type]![0];
    load = CancelableOperation.fromFuture(provider['data'](widget.data));
  }

  @override
  void dispose() {
    load.cancel();
    widget.data.mediaProv.clear();
    super.dispose();
  }

  Future<void> _updateProvider(Map<String, dynamic> newProvider) async {
    await load.cancel();
    setState(() {
      provider = newProvider;
      widget.data.mediaProv.clear();
      load = CancelableOperation.fromFuture(provider['data'](widget.data));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownMenu<Map<String, dynamic>>(
          initialSelection: provider,
          requestFocusOnTap: false,
          expandedInsets: EdgeInsets.zero,
          inputDecorationTheme:
              InputDecorationTheme(border: InputBorder.none, contentPadding: EdgeInsets.only(left: 15)),
          dropdownMenuEntries: List.generate(
            providers[widget.data.type]!.length,
            (index) => DropdownMenuEntry(
              value: providers[widget.data.type]![index],
              label: providers[widget.data.type]![index]['name'],
            ),
            growable: false,
          ),
          onSelected: (newProvider) async {
            if (newProvider != null) {
              await _updateProvider(newProvider);
            }
          },
        ),
        const SizedBox(
          height: 10,
        ),
        FutureBuilder<List<MediaProv>>(
          future: load.value,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snap.connectionState == ConnectionState.done && snap.hasData && snap.data!.isNotEmpty) {
              if (widget.data.mediaProv.isEmpty) {
                widget.data.mediaProv.addAll(snap.data!);
              }
              final split = snap.data!.slices(12).toList();
              return Column(
                children: [
                  if (split.length > 1)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          split.length,
                          (i) => TextButton(
                            onPressed: () => con.jumpToPage(i),
                            child: Text('${i + 1}'),
                          ),
                        ),
                      ),
                    ).padBottom(),
                  ExpandablePageView.builder(
                    itemCount: split.length,
                    scrollDirection: Axis.horizontal,
                    controller: con,
                    itemBuilder: (context, pindex) {
                      final List episodeGroup = split[pindex];
                      return ListView.builder(
                        shrinkWrap: true,
                        primary: false,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: episodeGroup.length,
                        itemBuilder: (context, gindex) {
                          final episode = episodeGroup[gindex];
                          return ListTile(
                            title: Text(episode.title),
                            subtitle: Text('$episodeLabel ${episode.number}'),
                            onTap: () => context.push(
                              '/${widget.data.type}/info/viewer',
                              extra: {
                                'index': (pindex * 12) + gindex,
                                'data': widget.data,
                              },
                            ),
                            trailing: Icon(Icons.play_arrow_rounded),
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
