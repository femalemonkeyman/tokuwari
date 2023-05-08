import 'dart:async';
import 'package:anicross/providers/anime_providers.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:wakelock/wakelock.dart';
import 'package:flutter/foundation.dart';
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
  final Player player = Player(
    configuration: const PlayerConfiguration(),
  );
  VideoController? controller;
  bool ready = false;
  int currentEpisode = 1;
  List subTracks = [];
  Map getMedia = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(
      [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    );
    Future.microtask(
      () async {
        controller = await VideoController.create(
          player,
        );
        if (!Platform.isLinux) {
          await Wakelock.enable();
        }
        getMedia = await mediaInfo(
              widget.episode['id'],
            ) ??
            widget.episode;
        if (getMedia.isNotEmpty) {
          final Directory dir = Directory(
            p.join(
              (await getTemporaryDirectory()).path,
              'anisubs',
            ),
          );
          if (getMedia['tracks'] != null) {
            for (final i in getMedia['tracks']) {
              if (i['kind'] == 'captions') {
                await Dio().download(
                  i['file'],
                  p.join(dir.path, "${i['label']}.vtt"),
                );
              }
            }
            await (player.platform as libmpvPlayer)
                .setProperty("sub-auto", 'all');
            await (player.platform as libmpvPlayer)
                .setProperty("sub-file-paths", dir.path);
          }
          await player.open(
            Media(
              getMedia['sources'].first['url'],
            ),
          );
          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(context) {
    if (getMedia.isNotEmpty && !kIsWeb) {
      return WillPopScope(
        onWillPop: () async {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          SystemChrome.setPreferredOrientations([]);
          if (!Platform.isLinux) {
            await Wakelock.disable();
          }
          await controller?.dispose();
          await player.dispose();
          try {
            Directory(
              p.join((await getTemporaryDirectory()).path, 'anisubs'),
            ).deleteSync(
              recursive: true,
            );
          } catch (e) {}
          return true;
        },
        child: Stack(
          children: [
            Video(controller: controller),
            VideoControls(
              player: player,
            ),
          ],
        ),
      );
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
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    Future.microtask(() async {
      if (!Platform.isAndroid && !Platform.isIOS) {
        await windowManager.setFullScreen(false);
      }
      await widget.player.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () => setState(() {
        (widget.player.state.playing)
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
            setState(
              () {
                show = false;
              },
            );
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
              Positioned(
                top: 0,
                right: 0,
                left: 0,
                child: Row(
                  children: [
                    const BackButton(),
                    const Spacer(),
                    PopupMenuButton(
                      itemBuilder: (context) {
                        return [
                          PopupMenuItem(
                            child: PopupMenuButton(
                              child: const Text('Subtitles'),
                              itemBuilder: (context) {
                                return List.generate(
                                  widget.player.state.tracks.subtitle.length,
                                  (index) {
                                    return PopupMenuItem(
                                      onTap: () {
                                        widget.player.setSubtitleTrack(
                                          widget.player.state.tracks
                                              .subtitle[index],
                                        );
                                      },
                                      child: Text(
                                        widget.player.state.tracks
                                                .subtitle[index].title ??
                                            widget.player.state.tracks
                                                .subtitle[index].id,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ];
                      },
                    )
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: 5, right: 20, left: 20),
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
                    Row(
                      children: [
                        const Spacer(),
                        IconButton(
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
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
