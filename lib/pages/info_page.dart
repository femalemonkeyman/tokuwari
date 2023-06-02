import '/media/providers/anime_providers.dart';
import '/models/info_models.dart';
import '/media/providers/manga_providers.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/image.dart';

class InfoPage extends StatefulWidget {
  final AniData data;

  const InfoPage({required this.data, super.key});

  @override
  State createState() => InfoPageState();
}

class InfoPageState extends State<InfoPage> {
  final List<MediaProv> content = [];
  final Isar isar = Isar.getInstance('later')!;

  @override
  void initState() {
    Future.microtask(
      () async {
        content.addAll(
          switch (widget.data.type) {
            'anime' => await zoroList(widget.data.mediaId),
            'manga' => await dexReader(widget.data.mediaId),
            _ => [],
          },
        );
        if (content.isEmpty) {
          content.addAll(await haniList(widget.data.title));
        }
        if (mounted) {
          setState(() {});
        }
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(context) {
    final Widget expands = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ActionChip(
          onPressed: () => setState(
            () {
              QueryBuilder<AniData, AniData, QAfterFilterCondition> media =
                  isar.aniDatas.filter().mediaIdMatches(
                        widget.data.mediaId,
                      );
              if (media.isEmptySync()) {
                isar.writeTxnSync(
                  () => isar.aniDatas.putSync(widget.data),
                );
              } else {
                isar.writeTxnSync(
                  () => media.deleteAllSync(),
                );
              }
            },
          ),
          avatar: (isar.aniDatas
                  .filter()
                  .mediaIdMatches(widget.data.mediaId)
                  .isEmptySync())
              ? const Icon(MdiIcons.bookmarkOutline)
              : const Icon(MdiIcons.bookmark),
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
                    borderRadius: BorderRadius.circular(12)),
                label: Text(
                  widget.data.tags[index],
                ),
                onPressed: () {
                  switch (widget.data.type) {
                    case 'anime':
                      {
                        context.go(
                          '/anime?tag=${widget.data.tags[index]}',
                        );
                      }
                    case 'manga':
                      {
                        context.go(
                          '/manga?tag=${widget.data.tags[index]}',
                        );
                      }
                  }
                },
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
              padding: const EdgeInsets.all(15),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      flex: 2,
                      fit: FlexFit.loose,
                      child: AniImage(
                        image: widget.data.image,
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Flexible(
                      flex: 4,
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
                          if (MediaQuery.of(context).size.width /
                                  MediaQuery.of(context).size.height >
                              1.2)
                            expands,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (MediaQuery.of(context).size.width /
                    MediaQuery.of(context).size.height <
                1.2)
              SliverPadding(
                padding: const EdgeInsets.only(
                  left: 15,
                  right: 15,
                ),
                sliver: SliverToBoxAdapter(
                  child: expands,
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
                          switch (widget.data.type) {
                            'anime' => '/anime/info/viewer',
                            'manga' => '/manga/info/viewer',
                            _ => '',
                          },
                          extra: {
                            'content': content[index],
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
