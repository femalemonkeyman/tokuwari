import 'package:anicross/anime/anime_videos.dart';
import 'package:anicross/manga/manga_reader.dart';
import 'package:anicross/providers/anime_providers.dart';
import 'package:anicross/providers/info_models.dart';
import 'package:anicross/providers/manga_providers.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'image.dart';

class InfoPage extends StatefulWidget {
  final AniData data;
  const InfoPage({required this.data, super.key});

  @override
  State createState() => InfoPageState();
}

class InfoPageState extends State<InfoPage> {
  List episodes = [];

  @override
  void initState() {
    Future.microtask(
      () async {
        episodes = (widget.data.type == "anime")
            ? await mediaList(widget.data.mediaId)
            : await dexReader(widget.data.mediaId);
        setState(() {});
      },
    );
    super.initState();
  }

  @override
  Widget build(context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  const Align(
                    alignment: Alignment.topLeft,
                    child: BackButton(),
                  ),
                  const Divider(
                    height: 15,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    flex: 2,
                    fit: FlexFit.tight,
                    child: AniImage(
                      image: widget.data.image,
                    ),
                  ),
                  const VerticalDivider(
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
                        const Divider(
                          height: 20,
                        ),
                        ActionChip(
                          onPressed: () {},
                          avatar: const Icon(MdiIcons.bookmark),
                          label: const Text("Later"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(
                      widget.data.tags.length.clamp(0, 20),
                      (index) {
                        return Chip(
                          label: Text(
                            widget.data.tags[index],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(
                    height: 15,
                  ),
                  ExpandableText(
                    widget.data.description,
                    expandText: "More",
                    collapseText: "Less",
                    maxLines: 8,
                  ),
                ],
              ),
            ),
            (episodes.isNotEmpty)
                ? SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      mainAxisSpacing: 5,
                      crossAxisSpacing: 6,
                      maxCrossAxisExtent: 400,
                      childAspectRatio: 4 / 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      childCount: episodes.length,
                      (context, index) {
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return Scaffold(
                                  body: (widget.data.type == "anime")
                                      ? AniViewer(
                                          episodes: episodes,
                                          episode: episodes[index],
                                        )
                                      : MangaReader(
                                          current: "",
                                          index: index,
                                          chapters: [],
                                        ),
                                );
                              },
                            ),
                          ),
                          child: Card(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    episodes[index]['title'],
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    episodes[index]['number'],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : const SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
