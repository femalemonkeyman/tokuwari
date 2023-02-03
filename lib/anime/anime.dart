import 'package:better_player/better_player.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:universal_io/io.dart';

import '../search_button.dart';
import 'anime_grid.dart';

final ValueNotifier<GraphQLClient> client = ValueNotifier(
  GraphQLClient(
    cache: GraphQLCache(),
    link: HttpLink(anilist),
  ),
);

const anilist = "https://graphql.anilist.co/";

const base = """
  {
  Page(perPage: 50, page: 1) {
    pageInfo {
      currentPage
      hasNextPage
    },
      media(sort: [TRENDING_DESC], type: ANIME) {
        id
        title {
          romaji
          english
          native
        }
        type
        chapters
        averageScore
        episodes
        description
        coverImage{
          extraLarge
        }
        episodes
        tags {
          name
        }
      }
  }
}
""";

const listSearch = """
query media(\$search: String!)
{
  Page(perPage: 50, page: 1,) {
    pageInfo {
      total
      perPage
      currentPage
      lastPage
      hasNextPage
    }
  	media(search: \$search, type: ANIME) {
  	    id
        title {
          romaji
          english
          native
        }
        type
        chapters
        averageScore
        episodes
        description
        coverImage{
          extraLarge
        }
        episodes
        tags {
          name
        }
  	}
  }
}
""";

aniInfo(id) async {
  String link = "https://api.consumet.org/meta/anilist/info/$id?provider=zoro";
  var json = await Dio().get(link);
  //print(json.data);
  return json.data;
}

episodeInfo(name) async {
  String link =
      "https://api.consumet.org/meta/anilist/watch/$name?provider=zoro";
  var json = await Dio().get(link);

  return json.data;
}

class AniPage extends StatelessWidget {
  const AniPage({Key? key}) : super(key: key);

  @override
  Widget build(context) {
    return ListView(
      controller: ScrollController(),
      primary: false,
      shrinkWrap: true,
      children: [
        const Center(
          child: SearchButton(
            text: "anilist",
          ),
        ),
        GraphQLProvider(
          client: client,
          child: Query(
            options: QueryOptions(
              document: gql(base),
            ),
            builder: (result, {refetch, fetchMore}) {
              if (result.hasException) {
                print(result.exception);
              }
              if (result.isNotLoading) {
                return AnimeGrid(
                  data: result.data!['Page']['media'],
                );
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class AniViewer extends StatefulWidget {
  final List sources;
  final List subtitles;
  const AniViewer({
    super.key,
    required this.sources,
    this.subtitles = const [],
  });

  @override
  State<StatefulWidget> createState() => AniViewerState();
}

class AniViewerState extends State<AniViewer> {
  Player? player;
  VideoController? controller;
  BetterPlayerController? phonePlayer;
  bool isPhone = Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    //print(widget.sources.first["url"]);
    print(widget.subtitles);
    List<String> subs = [];
    for (final i in widget.subtitles) {
      subs.add(i['url']);
    }
    if (isPhone) {
      BetterPlayerDataSource source = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.sources.first['url'],
        headers: {"User-Agent": "Death"},
        videoFormat: BetterPlayerVideoFormat.hls,
        subtitles: List.generate(widget.subtitles.length - 1, (index) {
          return BetterPlayerSubtitlesSource(
            selectedByDefault:
                (widget.subtitles[index]['lang'] == "English") ? true : false,
            type: BetterPlayerSubtitlesSourceType.network,
            name: widget.subtitles[index]['lang'],
            urls: [widget.subtitles[index]['url']],
          );
        }),
      );
      phonePlayer = BetterPlayerController(
        const BetterPlayerConfiguration(
          deviceOrientationsOnFullScreen: [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
          fullScreenByDefault: true,
          autoPlay: true,
          aspectRatio: 16 / 9,
          allowedScreenSleep: false,
          fit: BoxFit.contain,
        ),
        betterPlayerDataSource: source,
      );
      SystemChrome.setPreferredOrientations(
        [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
      );
    } else {
      player = Player(configuration: const PlayerConfiguration());
      Future.microtask(() async {
        controller = await VideoController.create(player!.handle);
        setState(() {});
      });
      player!.open(
        Playlist(
          [
            Media(
              widget.sources.first['url'],
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(context) {
    if (Platform.isWindows || Platform.isLinux) {
      return Video(
        controller: controller,
      );
    } else {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: BetterPlayer(
          controller: phonePlayer!,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      Future.microtask(() async {
        debugPrint('Disposing [Player] and [VideoController]...');
        await controller!.dispose();
        await player!.dispose();
      });
    }
    super.dispose();
  }
}

class AniEpisodes extends StatelessWidget {
  final id;
  const AniEpisodes({
    this.id,
    super.key,
  });

  @override
  Widget build(context) {
    return FutureBuilder<dynamic>(
      future: aniInfo(id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            shrinkWrap: true,
            itemCount: snapshot.data['episodes'].length,
            itemBuilder: ((context, index) {
              return ListTile(
                title: Text(
                  "Episode: ${snapshot.data['episodes'][index]['number']} - ${snapshot.data["episodes"][index]["title"]}",
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return Scaffold(
                        body: RawKeyboardListener(
                          autofocus: true,
                          focusNode: FocusNode(),
                          onKey: (value) {
                            if (value.isKeyPressed(LogicalKeyboardKey.escape)) {
                              Navigator.pop(context);
                            }
                          },
                          child: FutureBuilder<dynamic>(
                            future: episodeInfo(
                                snapshot.data['episodes'][index]['id']),
                            builder: (context, info) {
                              if (info.hasData) {
                                return AniViewer(
                                  sources: info.data['sources'],
                                  subtitles: info.data['subtitles'],
                                );
                              }
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
              // return DropdownButton(
              //   hint: Container(
              //     height: 40,
              //     decoration: const BoxDecoration(
              //         // border: Border(
              //         //   top: BorderSide(color: Colors.blueGrey),
              //         // ),
              //         ),
              //     child: Text(
              //         "Episode: ${snapshot.data['episodes'][index]['number']} - ${snapshot.data["episodes"][index]["title"]}"),
              //   ),
              //   items: [
              //     DropdownMenuItem(
              //       child: SizedBox.shrink(),
              //     )
              //   ],
              //   onChanged: (value) {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) {
              //           return Scaffold(
              //             body: RawKeyboardListener(
              //               autofocus: true,
              //               focusNode: FocusNode(),
              //               onKey: (value) {
              //                 if (value
              //                     .isKeyPressed(LogicalKeyboardKey.escape)) {
              //                   Navigator.pop(context);
              //                 }
              //               },
              //               child: FutureBuilder<dynamic>(
              //                 future: episodeInfo(
              //                     snapshot.data['episodes'][index]['id']),
              //                 builder: (context, info) {
              //                   if (info.hasData) {
              //                     return AniViewer(
              //                       server: info.data['sources'],
              //                     );
              //                   }
              //                   return const Center(
              //                     child: CircularProgressIndicator(),
              //                   );
              //                 },
              //               ),
              //             ),
              //           );
              //         },
              //       ),
              //     );
              //   },
              // );
            }),
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
