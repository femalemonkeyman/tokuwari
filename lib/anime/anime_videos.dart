import 'dart:async';
import 'package:anicross/providers/anime_providers.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:better_player/better_player.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';
import 'package:window_manager/window_manager.dart';

class AniViewer extends StatefulWidget {
  final List episodes;
  final Map episode;

  const AniViewer({super.key, required this.episodes, required this.episode});

  @override
  State<StatefulWidget> createState() => AniViewerState();
}

class AniViewerState extends State<AniViewer> {
  Player? player;
  VideoController? controller;
  BetterPlayerController? phonePlayer;
  int currentEpisode = 1;
  List subtitles = [];
  Map getMedia = {};

  bool isPhone = Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () async {
        getMedia = await mediaInfo(
              widget.episode['id'],
            ) ??
            widget.episode;
        setState(() {});
      },
    );
  }

  Future desktopPlayer(String url) async {
    player = Player(
      configuration: const PlayerConfiguration(),
    );
    controller = await VideoController.create(
      player!.handle,
    );
    if (getMedia['subtitles'] != null) {
      Directory dir = await getTemporaryDirectory();
      String path = "";
      for (final i in getMedia['subtitles']) {
        await Dio().download(i['url'], "${dir.path}/${i['lang']}subs.vtt");
        if (i['lang'] == "English") {
          path = "${dir.path}/${i['lang']}subs.vtt";
        }
      }
      await (player!.platform as libmpvPlayer).setProperty("sub-files", path);
    }
    await player!.open(
      Playlist(
        [
          Media(
            url,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(context) {
    if (getMedia.isNotEmpty) {
      if (isPhone) {
        BetterPlayerDataSource source = BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          getMedia['sources']!.first['url'],
          headers: {"User-Agent": "Death"},
          videoFormat: BetterPlayerVideoFormat.hls,
          subtitles: (subtitles.isNotEmpty)
              ? List.generate(
                  subtitles.length - 1,
                  (index) {
                    return BetterPlayerSubtitlesSource(
                      selectedByDefault: (subtitles[index]['lang'] == "English")
                          ? true
                          : false,
                      type: BetterPlayerSubtitlesSourceType.network,
                      name: subtitles[index]['lang'],
                      urls: [
                        subtitles[index]['url'],
                      ],
                    );
                  },
                )
              : null,
        );
        phonePlayer = BetterPlayerController(
          const BetterPlayerConfiguration(
            useRootNavigator: true,
            controlsConfiguration: BetterPlayerControlsConfiguration(
              playerTheme: BetterPlayerTheme.material,
            ),
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
        return BetterPlayer(
          controller: phonePlayer!,
        );
      } else {
        return FutureBuilder(
          future: desktopPlayer(
            getMedia['sources'].last['url'],
          ),
          builder: (context, innerSnap) {
            if (innerSnap.connectionState == ConnectionState.done) {
              return Stack(
                children: [
                  Video(controller: controller),
                  VideoControls(
                    player: player!,
                  ),
                ],
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
      }
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton(
            onPressed: () => Navigator.maybePop(context),
            child: const Text("Escape?"),
          ),
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (!isPhone) {
      Future.microtask(() async {
        await controller!.dispose();
        await player!.dispose();
      });
    }
  }
}

class VideoControls extends StatefulWidget {
  final Player player;

  const VideoControls({required this.player, super.key});
  @override
  State<StatefulWidget> createState() => VideoControlsState();
}

class VideoControlsState extends State<VideoControls> {
  bool fullscreen = false;
  bool show = false;
  Timer? timer;

  @override
  void dispose() {
    timer!.cancel();
    Future.microtask(() async {
      await windowManager.setFullScreen(false);
      await widget.player.dispose();
    });
    super.dispose();
  }

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
              Positioned(
                right: 20,
                bottom: 0,
                child: IconButton(
                  iconSize: 50,
                  onPressed: () async {
                    if (fullscreen) {
                      await windowManager.setFullScreen(false);
                      fullscreen = false;
                    } else {
                      await windowManager.setFullScreen(true);
                      fullscreen = true;
                    }
                    setState(() {});
                  },
                  icon: (fullscreen)
                      ? const Icon(Icons.fullscreen_exit_outlined)
                      : const Icon(
                          Icons.fullscreen_outlined,
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
