import 'package:anicross/anime/anime.dart';
import 'package:anicross/manga/manga.dart';
import 'package:anicross/providers/info_models.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';

import 'image.dart';

class InfoPage extends StatelessWidget {
  final AniData data;

  const InfoPage({required this.data, super.key});

  @override
  Widget build(context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              right: 20,
              left: 20,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.topLeft,
                      child: BackButton(),
                    ),
                    const Divider(
                      height: 15,
                    ),
                    Flexible(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            flex: 2,
                            child: AniImage(
                              image: data.image,
                            ),
                          ),
                          const VerticalDivider(
                            width: 20,
                          ),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                  ),
                                ),
                                const Divider(
                                  height: 30,
                                ),
                                Wrap(
                                  children: List.generate(
                                    data.tags.length.clamp(0, 20),
                                    (index) {
                                      return Container(
                                        margin: const EdgeInsets.all(1),
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple[900],
                                          border: Border.all(width: 1),
                                          borderRadius:
                                              BorderRadius.circular(50),
                                        ),
                                        child: Text(
                                          data.tags[index],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const Divider(
                                  height: 10,
                                ),
                                ExpandableText(
                                  data.description,
                                  expandText: "More",
                                  collapseText: "Less",
                                  maxLines: 8,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 30,
                    ),
                    (data.type == "anime")
                        ? AniEpisodes(
                            id: data.mediaId,
                          )
                        : MangaChapters(id: data.mediaId)
                    //mediaList,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
