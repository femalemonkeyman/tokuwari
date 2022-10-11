import 'package:better_player/better_player.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_io/io.dart';
import 'package:video_player/video_player.dart';

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

class AniViewer extends StatefulWidget {
  Map server;
  String? headers;
  AniViewer({super.key, required this.server, this.headers});

  @override
  State<StatefulWidget> createState() => AniViewerState();
}

class AniViewerState extends State<AniViewer> {
  dynamic player;
  bool isPhone = Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (isPhone) {
      BetterPlayerDataSource source = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.server['url'],
        headers: {"User-Agent": "Death"},
        videoFormat: BetterPlayerVideoFormat.hls,
      );
      player = BetterPlayerController(
        BetterPlayerConfiguration(
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
          widget.server,
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
                                headers: info.data['headers']["Referer"],
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
