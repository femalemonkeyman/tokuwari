import 'package:async/async.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:tokuwari_models/info_models.dart';
import '../media/providers/providers.dart';
import 'package:expandable_text/expandable_text.dart';
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
    final Widget expands = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LaterButton(
          data: data,
        ).padBottom(),
        ExpandableText(
          data.description,
          expandText: "More",
          collapseText: "Less",
          maxLines: 4,
        ).padBottom(),
        Wrap(
          spacing: 3,
          runSpacing: 7,
          children: List.generate(
            data.tags.length.clamp(0, 15),
            (index) {
              return ActionChip(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Colors.blueGrey[800],
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                label: Text(
                  data.tags[index],
                ),
                onPressed: () => context.go(
                  '/${data.type}?tag=${data.tags[index]}',
                ),
              );
            },
          ),
        ).padBottom(),
      ],
    );
    final double ratio = MediaQuery.of(context).size.width / MediaQuery.of(context).size.height;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Continue?'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(data.title),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: 10,
              ),
              sliver: SliverList.list(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        flex: 7,
                        fit: FlexFit.tight,
                        child: AniImage(
                          image: data.image,
                        ).padBottom(),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Expanded(
                        flex: 15,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.title,
                              style: const TextStyle(
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              data.status,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Score: ${data.score}',
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Count: ${data.count}',
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ).padBottom(),
                            if (ratio > 1.2) expands,
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (ratio < 1.2) expands,
                  //  ⠄⠄⡔⠙⠢⡀⠄⠄⠄⢀⠼⠅⠈⢂⠄⠄⠄⠄
                  //  ⠄⠄⡌⠄⢰⠉⢙⢗⣲⡖⡋⢐⡺⡄⠈⢆⠄⠄⠄
                  //  ⠄⡜⠄⢀⠆⢠⣿⣿⣿⣿⢡⢣⢿⡱⡀⠈⠆⠄⠄
                  //  ⠄⠧⠤⠂⠄⣼⢧⢻⣿⣿⣞⢸⣮⠳⣕⢤⡆⠄⠄
                  //  ⢺⣿⣿⣶⣦⡇⡌⣰⣍⠚⢿⠄⢩⣧⠉⢷⡇⠄⠄
                  //  ⠘⣿⣿⣯⡙⣧⢎⢨⣶⣶⣶⣶⢸⣼⡻⡎⡇⠄⠄
                  //  ⠄⠘⣿⣿⣷⡀⠎⡮⡙⠶⠟⣫⣶⠛⠧⠁⠄⠄⠄
                  //  ⠄⠄⠘⣿⣿⣿⣦⣤⡀⢿⣿⣿⣿⣄⠄⠄⠄⠄⠄
                  //  ⠄⠄⠄⠈⢿⣿⣿⣿⣿⣷⣯⣿⣿⣷⣾⣿⣷⡄⠄
                  //  ⠄⠄⠄⠄⠄⢻⠏⣼⣿⣿⣿⣿⡿⣿⣿⣏⢾⠇⠄
                  //  ⠄⠄⠄⠄⠄⠈⡼⠿⠿⢿⣿⣦⡝⣿⣿⣿⠷⢀⠄
                  //  ⠄⠄⠄⠄⠄⠄⡇⠄⠄⠄⠈⠻⠇⠿⠋⠄⠄⢘⡆
                  //  ⠄⠄⠄⠄⠄⠄⠱⣀⠄⠄⠄⣀⢼⡀⠄⢀⣀⡜⠄
                  //  ⠄⠄⠄⠄⠄⠄⠄⢸⣉⠉⠉⠄⢀⠈⠉⢏⠁⠄⠄
                  //  ⠄⠄⠄⠄⠄⠄⡰⠃⠄⠄⠄⠄⢸⠄⠄⢸⣧⠄⠄
                  //  ⠄⠄⠄⠄⠄⣼⣧⠄⠄⠄⠄⠄⣼⠄⠄⡘⣿⡆⠄
                  //  ⠄⠄⠄⢀⣼⣿⡙⣷⡄⠄⠄⠄⠃⠄⢠⣿⢸⣿⡀
                  //  ⠄⠄⢀⣾⣿⣿⣷⣝⠿⡀⠄⠄⠄⢀⡞⢍⣼⣿⠇
                  //  ⠄⠄⣼⣿⣿⣿⣿⣿⣷⣄⠄⠄⠠⡊⠴⠋⠹⡜⠄
                  //  ⠄⠄⣿⣿⣿⣿⣿⣿⣿⣿⡆⣤⣾⣿⣿⣧⠹⠄⠄
                  //  ⠄⠄⢿⣿⣿⣿⣿⣿⣿⣿⢃⣿⣿⣿⣿⣿⡇⠄⠄
                  //  ⠄⠄⠐⡏⠉⠉⠉⠉⠉⠄⢸⠛⠿⣿⣿⡟⠄⠄⠄
                  //  ⠄⠄⠄⠹⡖⠒⠒⠒⠒⠊⢹⠒⠤⢤⡜⠁⠄⠄⠄
                  //  ⠄⠄⠄⠄⠱⠄⠄⠄⠄⠄⢸
                ],
              ),
            ),
            Selector(
              data: data,
            ),
          ],
        ),
      ),
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
  late final media = widget.isar.aniDatas.where().mediaIdEqualTo(
        widget.data.mediaId,
      );
  @override
  Widget build(context) => ActionChip(
        shape: const StadiumBorder(),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        onPressed: () => setState(
          () {
            if (media.isEmpty()) {
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
        avatar: (media.isEmpty()) ? const Icon(Icons.bookmark_add_outlined) : const Icon(Icons.bookmark_added_rounded),
        label: const Text("Later"),
      );
}

class Selector extends StatefulWidget {
  final AniData data;

  const Selector({
    super.key,
    required this.data,
  });

  @override
  State createState() => SelectorState();
}

class SelectorState extends State<Selector> {
  late Map provider = providers[widget.data.type]![0];
  late CancelableOperation<List<MediaProv>> load = CancelableOperation.fromFuture(provider['data'](widget.data));

  @override
  void dispose() {
    super.dispose();
    widget.data.mediaProv.clear();
    load.cancel();
  }

  @override
  Widget build(context) {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      sliver: SliverList.list(
        children: [
          DropdownButton(
            value: provider,
            padding: const EdgeInsets.only(left: 15),
            underline: const SizedBox.shrink(),
            focusColor: const Color.fromARGB(0, 0, 0, 0),
            borderRadius: BorderRadius.circular(30),
            items: List.generate(
              providers[widget.data.type]!.length,
              (index) => DropdownMenuItem(
                value: providers[widget.data.type]![index],
                child: Text(
                  providers[widget.data.type]![index]['name'],
                ),
              ),
              growable: false,
            ),
            onChanged: (value) async {
              await load.cancel();
              setState(() {
                widget.data.mediaProv.clear();
                load = CancelableOperation.fromFuture(value!['data'](widget.data));
                provider = value;
              });
            },
          ),
          const SizedBox(
            height: 10,
          ),
          FutureBuilder(
            future: load.value,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.done && snap.requireData.isNotEmpty) {
                if (widget.data.mediaProv.isEmpty) {
                  widget.data.mediaProv.addAll(snap.requireData);
                }
                final split = snap.requireData.slices(24).toList();
                return EpisodeList(split: split, data: widget.data);
              }
              if (snap.connectionState == ConnectionState.done && snap.requireData.isEmpty) {
                return const SizedBox.shrink();
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ],
      ),
    );
  }
}

class EpisodeList extends StatelessWidget {
  final List<List> split;
  final AniData data;

  const EpisodeList({super.key, required this.split, required this.data});

  @override
  Widget build(context) {
    return ExpandablePageView.builder(
      pageSnapping: false,
      itemCount: split.length,
      scrollDirection: Axis.horizontal,
      itemBuilder: (BuildContext context, int pindex) {
        return GridView.custom(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            mainAxisSpacing: 5,
            crossAxisSpacing: 6,
            maxCrossAxisExtent: 400,
            mainAxisExtent: 100,
          ),
          childrenDelegate: SliverChildBuilderDelegate(
            childCount: split[pindex].length,
            (context, gindex) => GestureDetector(
              onTap: () => context.push(
                '/${data.type}/info/viewer',
                extra: {
                  'index': (pindex * 24) + gindex,
                  'data': data,
                },
              ),
              child: Card(
                elevation: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Text(
                          split[pindex][gindex].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '${(data.type == 'anime') ? 'Episode:' : 'Chapter:'} ${split[pindex][gindex].number}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).padBottom();
  }
}
