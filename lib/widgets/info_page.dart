import 'package:anicross/anime/anime.dart';
import 'package:anicross/anime/anime_videos.dart';
import 'package:anicross/manga/manga.dart';
import 'package:anicross/manga/manga_reader.dart';
import 'package:anicross/providers/anime_providers.dart';
import 'package:anicross/providers/info_models.dart';
import 'package:anicross/providers/manga_providers.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BackButton(),
                    const Divider(
                      height: 15,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          flex: 2,
                          fit: FlexFit.tight,
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
                                    return Chip(
                                      label: Text(
                                        data.tags[index],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const Divider(
                                height: 15,
                              ),
                              ActionChip(
                                onPressed: () {},
                                avatar: const Icon(MdiIcons.bookmark),
                                label: const Text("Later"),
                              ),
                              const Divider(
                                height: 15,
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
                    const Divider(
                      height: 30,
                    ),
                    FutureBuilder<List>(
                      future: (data.type == "anime")
                          ? mediaList(data.mediaId)
                          : dexReader(data.mediaId),
                      builder: (context, snap) {
                        //print(snap.error);
                        if (snap.hasData) {
                          //print(snap.data);
                          return GridView(
                            shrinkWrap: true,
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              mainAxisSpacing: 5,
                              crossAxisSpacing: 6,
                              maxCrossAxisExtent: 400,
                              childAspectRatio: 4 / 1,
                            ),
                            children: List.generate(
                              snap.data!.length,
                              (index) {
                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return Scaffold(
                                          body: (data.type == "anime")
                                              ? AniViewer(
                                                  episodes: snap.data!,
                                                  episode: snap.data![index],
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
                                      children: [
                                        Text(
                                          snap.data![index]['title'],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    )
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
