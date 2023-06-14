import '../media/providers/providers.dart';
import '/models/info_models.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/image.dart';

class InfoPage extends StatefulWidget {
  final AniData data;
  final Isar isar = Isar.getInstance('later')!;

  InfoPage({required this.data, super.key});

  @override
  State createState() => InfoPageState();
}

class InfoPageState extends State<InfoPage> {
  final List<MediaProv> content = [];
  late Function init = providers[widget.data.type]![0]['data'];

  @override
  void initState() {
    Future.microtask(
      () async {
        content.addAll(
          await init(widget.data),
        );
        if (mounted) {
          setState(() {});
        }
      },
    );
    super.initState();
  }

  @override
  Widget build(context) {
    final double ratio =
        MediaQuery.of(context).size.width / MediaQuery.of(context).size.height;
    final Widget expands = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ActionChip(
          shape: const StadiumBorder(),
          onPressed: () => setState(
            () {
              final media = widget.isar.aniDatas.filter().mediaIdMatches(
                    widget.data.mediaId,
                  );
              if (media.isEmptySync()) {
                widget.isar.writeTxnSync(
                  () => widget.isar.aniDatas.putSync(widget.data),
                );
              } else {
                widget.isar.writeTxnSync(
                  () => media.deleteAllSync(),
                );
              }
            },
          ),
          avatar: (widget.isar.aniDatas
                  .filter()
                  .mediaIdMatches(widget.data.mediaId)
                  .isEmptySync())
              ? Icon(MdiIcons.bookmarkOutline)
              : Icon(MdiIcons.bookmark),
          label: const Text("Later"),
        ),
        const SizedBox(
          height: 10,
        ),
        ExpandableText(
          widget.data.description,
          expandText: "More",
          collapseText: "Less",
          maxLines: 4,
        ),
        const SizedBox(
          height: 15,
        ),
        Wrap(
          spacing: 3,
          runSpacing: 7,
          children: List.generate(
            widget.data.tags.length.clamp(0, 15),
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
                  widget.data.tags[index],
                ),
                onPressed: () => context.go(
                  '/${widget.data.type}?tag=${widget.data.tags[index]}',
                ),
              );
            },
          ),
        ),
      ],
    );
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(widget.data.title),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 15,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      flex: 7,
                      fit: FlexFit.tight,
                      child: AniImage(
                        image: widget.data.image,
                      ),
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
                            widget.data.title,
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          if (ratio > 1.2) expands,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (ratio < 1.2)
              SliverPadding(
                padding: const EdgeInsets.only(
                  left: 15,
                  right: 15,
                ),
                sliver: SliverToBoxAdapter(
                  child: expands,
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
              sliver: SliverToBoxAdapter(
                child: DropdownButton(
                  value: init,
                  padding: const EdgeInsets.only(left: 20),
                  underline: const SizedBox.shrink(),
                  focusColor: const Color.fromARGB(0, 0, 0, 0),
                  borderRadius: BorderRadius.circular(30),
                  items: List.generate(
                    providers[widget.data.type]!.length,
                    (index) => DropdownMenuItem(
                      value: providers[widget.data.type]![index]['data'],
                      child: Text(
                        providers[widget.data.type]![index]['name'],
                      ),
                    ),
                    growable: false,
                  ),
                  onChanged: (value) => Future.microtask(
                    () async {
                      content
                        ..clear()
                        ..addAll(
                          await (value as Function)(widget.data),
                        );
                      setState(
                        () {
                          init = value;
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            if (content.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(15),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 6,
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 100,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    childCount: content.length,
                    (context, index) {
                      return GestureDetector(
                        onTap: () => context.push(
                          '/${widget.data.type}/info/viewer',
                          extra: {
                            'content': index,
                            'contents': content,
                          },
                        ),
                        child: Card(
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    content[index].title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    '${(widget.data.type == 'anime') ? 'Episode:' : 'Chapter:'} ${content[index].number}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
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
