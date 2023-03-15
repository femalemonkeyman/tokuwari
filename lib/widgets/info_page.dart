import 'package:anicross/anime/anime.dart';
import 'package:anicross/manga/manga.dart';
import 'package:anicross/providers/info_models.dart';
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
                              ActionChip(
                                onPressed: () {},
                                avatar: const Icon(MdiIcons.bookmark),
                                label: const Text("Later"),
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
