import 'dart:async';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:subtitle/subtitle.dart';
import 'package:universal_io/io.dart';

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
    if (!isPhone) {
      return Stack(
        children: [
          Video(controller: controller),
          Positioned(
            left: 0, //MediaQuery.of(context).size.width / 0,
            right: 0,
            bottom: 0,
            child: AnimeSubtitles(
              url: widget.subtitles.first['url'],
              player: player!,
            ),
          ),
          VideoControls(
            player: player!,
          ),
        ],
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
    if (!isPhone) {
      Future.microtask(() async {
        debugPrint('Disposing [Player] and [VideoController]...');
        await controller!.dispose();
        await player!.dispose();
      });
    }
    super.dispose();
  }
}

class VideoControls extends StatefulWidget {
  final Player player;

  const VideoControls({required this.player, super.key});
  @override
  State<StatefulWidget> createState() => VideoControlsState();
}

class VideoControlsState extends State<VideoControls> {
  @override
  void dispose() {
    timer!.cancel();
    super.dispose();
  }

  bool show = false;
  Timer? timer;
  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () => setState(() {
        (widget.player.state.isPlaying)
            ? widget.player.pause()
            : widget.player.play();
      }),
      child: MouseRegion(
        onHover: (event) {
          setState(() {
            if (timer != null) {
              timer!.cancel();
            }
            show = true;
          });
          timer = Timer(const Duration(seconds: 3), () {
            setState(() {
              show = false;
            });
          });
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: !show ? 0.0 : 1.0,
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xCC000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0xCC000000),
                    ],
                  ),
                ),
              ),
              const BackButton(),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding:
                      const EdgeInsets.only(bottom: 60, right: 20, left: 20),
                  child: StreamBuilder<Duration>(
                    stream: widget.player.streams.position,
                    builder: (BuildContext context,
                        AsyncSnapshot<Duration> snapshot) {
                      if (snapshot.hasData) {
                        return Theme(
                          data: ThemeData.dark(),
                          child: ProgressBar(
                            progress: snapshot.data!,
                            total: widget.player.state.duration,
                            barHeight: 3,
                            timeLabelLocation: TimeLabelLocation.sides,
                            onSeek: (duration) {
                              widget.player.seek(duration);
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimeSubtitles extends StatefulWidget {
  final String url;
  final Player player;

  const AnimeSubtitles({required this.url, required this.player, super.key});
  @override
  State createState() => AnimeSubtitlesState();
}

class AnimeSubtitlesState extends State<AnimeSubtitles> {
  late SubtitleController controller;

  @override
  void initState() {
    controller = SubtitleController(
      provider: SubtitleProvider.fromNetwork(
        Uri.parse(widget.url),
      ),
    );
    controller.initial();
    super.initState();
  }

  @override
  Widget build(context) {
    return StreamBuilder(
      stream: widget.player.streams.position,
      builder: (context, AsyncSnapshot<Duration> snapshot) {
        if (snapshot.hasData) {
          return SizedBox(
            height: 150,
            width: 800,
            child: Text(
              controller.durationSearch(snapshot.data!)?.data ?? "",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
