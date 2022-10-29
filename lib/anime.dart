import 'package:better_player/better_player.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:universal_io/io.dart';
import 'anigrid.dart';
import 'anisearch.dart';

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
  	  title {
  	    romaji
  	    english
  	    native
  	  }
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
  String link = "https://api.consumet.org/meta/anilist/info/$id";
  var json = await Dio().get(link);
  return json.data;
}

episodeInfo(name) async {
  String link = "https://api.consumet.org/meta/anilist/watch/$name";
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
                var data = result.data!['Page']['media'];
                return AniGrid(
                  data: data,
                  place: "anilist",
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
  final Map server;
  const AniViewer({
    super.key,
    required this.server,
  });

  @override
  State<StatefulWidget> createState() => AniViewerState();
}

class AniViewerState extends State<AniViewer> {
  dynamic player;
  bool isPhone = Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    if (isPhone) {
      BetterPlayerDataSource source = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.server['url'],
        headers: {"User-Agent": "Death"},
        videoFormat: BetterPlayerVideoFormat.hls,
      );
      player = BetterPlayerController(
        const BetterPlayerConfiguration(
            deviceOrientationsOnFullScreen: [DeviceOrientation.landscapeLeft],
            fullScreenByDefault: true,
            autoPlay: true,
            allowedScreenSleep: false),
        betterPlayerDataSource: source,
      );
    } else {
      player = Player(
        id: 1,
        registerTexture: true,
        commandlineArguments: Platform.isLinux ? ["--demux=ffmpeg"] : [],
      );
      player.open(
        Media.network(
          widget.server['url'],
        ),
      );
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      body: GestureDetector(
        child: !isPhone
            ? Video(
                player: player,
                showFullscreenButton: true,
              )
            : BetterPlayer(
                controller: player,
              ),
      ),
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}

class AniEpisodes extends StatelessWidget {
  final id;
  const AniEpisodes({this.id, super.key});

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
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return Scaffold(
                        body: FutureBuilder<dynamic>(
                          future: episodeInfo(
                              snapshot.data['episodes'][index]['id']),
                          builder: (context, info) {
                            if (info.hasData) {
                              return AniViewer(
                                server: info.data['sources'][
                                    info.data['sources'].indexWhere((source) =>
                                        source['quality'] == "1080p")],
                              );
                            }
                            return const CircularProgressIndicator();
                          },
                        ),
                      );
                    },
                  ),
                ),
                child: Container(
                  height: 40,
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.blueGrey)),
                  ),
                  child: Text(
                      "Episode: ${snapshot.data['episodes'][index]['number']} ${snapshot.data["episodes"][index]["title"]}"),
                ),
              );
            }),
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
