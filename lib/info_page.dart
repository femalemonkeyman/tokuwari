import 'package:anicross/anime/anime_videos.dart';
import 'package:anicross/manga/manga_reader.dart';
import 'package:anicross/providers/anime_providers.dart';
import 'package:anicross/providers/info_models.dart';
import 'package:anicross/providers/manga_providers.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'widgets/image.dart';

class InfoPage extends StatefulWidget {
  final AniData data;
  const InfoPage({required this.data, super.key});

  @override
  State createState() => InfoPageState();
}

class InfoPageState extends State<InfoPage> {
  List content = [];

  @override
  void initState() {
    Future.microtask(
      () async {
        content = (widget.data.type == "anime")
            ? await mediaList(widget.data.mediaId)
            : await dexReader(widget.data.mediaId);
        setState(() {});
      },
    );
    super.initState();
  }

  @override
  Widget build(context) {
    final expands = Column(
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
    );
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.only(left: 15, top: 15),
              sliver: SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: BackButton(),
                ),
              ),
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
                          if (MediaQuery.of(context).size.width /
                                  MediaQuery.of(context).size.height >
                              1.5)
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
                1.5)
              SliverPadding(
                padding: const EdgeInsets.only(
                  left: 15,
                  right: 15,
                ),
                sliver: SliverToBoxAdapter(
                  child: expands,
                ),
              ),
            (content.isNotEmpty)
                ? SliverPadding(
                    padding: const EdgeInsets.all(15),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        mainAxisSpacing: 5,
                        crossAxisSpacing: 6,
                        maxCrossAxisExtent: 400,
                        mainAxisExtent: 100,
                        //childAspectRatio: 4 / 1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        childCount: content.length,
                        (context, index) {
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return Scaffold(
                                    body: (widget.data.type == "anime")
                                        ? AniViewer(
                                            episodes: content,
                                            episode: content[index],
                                          )
                                        : MangaReader(
                                            chapter: content[index],
                                            chapters: content,
                                          ),
                                  );
                                },
                              ),
                            ),
                            child: IntrinsicHeight(
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
                                          content[index]['title'],
                                          overflow: TextOverflow.visible,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          content[index]['number'],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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
