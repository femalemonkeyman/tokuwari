import 'dart:async';
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
    if (isPhone) {
      BetterPlayerDataSource source = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.sources.first['url'],
        headers: {"User-Agent": "Death"},
        videoFormat: BetterPlayerVideoFormat.hls,
        subtitles: List.generate(
          widget.subtitles.length - 1,
          (index) {
            return BetterPlayerSubtitlesSource(
              selectedByDefault:
                  (widget.subtitles[index]['lang'] == "English") ? true : false,
              type: BetterPlayerSubtitlesSourceType.network,
              name: widget.subtitles[index]['lang'],
              urls: [
                widget.subtitles[index]['url'],
              ],
            );
          },
        ),
      );
      phonePlayer = BetterPlayerController(
        const BetterPlayerConfiguration(
          controlsConfiguration: BetterPlayerControlsConfiguration(),
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
    } else {
      player = Player(configuration: const PlayerConfiguration());
      Future.microtask(() async {
        controller = await VideoController.create(player!.handle);
        Directory dir = await getTemporaryDirectory();
        String path = "";
        for (final i in widget.subtitles) {
          await Dio().download(i['url'], "${dir.path}/${i['lang']}subs.vtt");
          if (i['lang'] == "English") {
            path = "${dir.path}/${i['lang']}subs.vtt";
          }
        }
        (player!.platform as libmpvPlayer).setProperty("sub-files", path);
        setState(() {});
      });
      player!.open(
        Playlist(
          [
            Media(
              widget.sources.last['url'],
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
          VideoControls(
            player: player!,
          ),
        ],
      );
    } else {
      return BetterPlayer(
        controller: phonePlayer!,
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
