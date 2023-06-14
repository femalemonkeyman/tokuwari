import 'dart:async';
import 'package:go_router/go_router.dart';
import '/models/info_models.dart';
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
import 'dart:io';
import 'package:window_manager/window_manager.dart';

class AniViewer extends StatefulWidget {
  final List<MediaProv> episodes;
  final int episode;

  const AniViewer({super.key, required this.episodes, required this.episode});

  @override
  State<StatefulWidget> createState() => AniViewerState();
}

class AniViewerState extends State<AniViewer> {
  final Player player = Player();
  late final VideoController controller = VideoController(player);
  late final double height = MediaQuery.of(context).size.height;
  final List subTracks = [];
  late int currentEpisode = widget.episode;
  bool ready = false;
  Source getMedia = Source(qualities: {}, subtitles: []);
  bool fullscreen = false;
  bool show = false;
  Timer? timer;

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
        if (!Platform.isLinux) {
          await Wakelock.enable();
        }
        getMedia = await widget.episodes[currentEpisode].call!();
        if (getMedia.qualities.isNotEmpty) {
          final Directory dir = Directory(
            p.join(
              (await getTemporaryDirectory()).path,
              'anisubs',
            ),
          );
          if (getMedia.subtitles.isNotEmpty) {
            for (final Map i in getMedia.subtitles) {
              await Dio().download(
                i['url'],
                p.join(dir.path, "${i['lang']}.vtt"),
              );
            }
            (player.platform as libmpvPlayer)
              ..setProperty("sub-auto", 'all')
              ..setProperty("sub-file-paths", dir.path)
              ..setProperty(
                  'sid',
                  '${getMedia.subtitles.lastIndexWhere(
                        (element) =>
                            element['lang']!.toLowerCase().contains('english'),
                      ) + 1}');
          }
          await player.open(
            Media(
              getMedia.qualities.values.first,
              httpHeaders: getMedia.headers ?? {},
            ),
          );
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    Future.microtask(
      () async {
        if (!Platform.isLinux) {
          await Wakelock.disable();
        }
        try {
          Directory(
            p.join((await getTemporaryDirectory()).path, 'anisubs'),
          ).deleteSync(
            recursive: true,
          );
        } catch (e) {}
        if (!Platform.isAndroid && !Platform.isIOS) {
          await windowManager.setFullScreen(false);
        }
        await player.dispose();
      },
    );
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(context) {
    return Scaffold(
      body: (getMedia.qualities.isNotEmpty && !kIsWeb)
          ? Stack(
              children: [
                Video(controller: controller),
                GestureDetector(
                  onTap: () => player.playOrPause(),
                  child: MouseRegion(
                    onHover: (event) {
                      setState(() {
                        if (timer != null) {
                          timer?.cancel();
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
                      child: AbsorbPointer(
                        absorbing: !show,
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
                                          child: const Text('Subtitles'),
                                          onTap: () => showBottomSheet(
                                            context: context,
                                            constraints:
                                                BoxConstraints.tightFor(
                                              height: height / 2,
                                            ),
                                            builder: (context) => ListView(
                                              children: List.generate(
                                                player.state.tracks.subtitle
                                                    .length,
                                                (index) {
                                                  return ListTile(
                                                    title: Text(
                                                      player
                                                              .state
                                                              .tracks
                                                              .subtitle[index]
                                                              .title ??
                                                          player
                                                              .state
                                                              .tracks
                                                              .subtitle[index]
                                                              .id,
                                                    ),
                                                    onTap: () {
                                                      player.setSubtitleTrack(
                                                        player.state.tracks
                                                            .subtitle[index],
                                                      );
                                                      context.pop();
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          child: const Text('Quality'),
                                          onTap: () => showBottomSheet(
                                            context: context,
                                            constraints:
                                                BoxConstraints.tightFor(
                                              height: height / 2,
                                            ),
                                            builder: (context) => ListView(
                                              children: List.generate(
                                                player
                                                    .state.tracks.video.length,
                                                (index) {
                                                  return ListTile(
                                                    title: Text(
                                                      player
                                                              .state
                                                              .tracks
                                                              .video[index]
                                                              .title ??
                                                          player.state.tracks
                                                              .video[index].id,
                                                    ),
                                                    onTap: () {
                                                      player.setVideoTrack(
                                                        player.state.tracks
                                                            .video[index],
                                                      );
                                                      context.pop();
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ];
                                    },
                                  ),
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
                                    padding: const EdgeInsets.only(
                                        bottom: 5, right: 20, left: 20),
                                    child: StreamBuilder<Duration>(
                                      stream: player.streams.position,
                                      builder: (BuildContext context,
                                          AsyncSnapshot<Duration> snapshot) {
                                        if (snapshot.hasData) {
                                          return Theme(
                                            data: ThemeData.dark(),
                                            child: ProgressBar(
                                              progress: snapshot.data!,
                                              total: player.state.duration,
                                              barHeight: 3,
                                              timeLabelLocation:
                                                  TimeLabelLocation.sides,
                                              onSeek: (duration) {
                                                player.seek(duration);
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
                                          await windowManager.setFullScreen(
                                            !fullscreen,
                                          );
                                          fullscreen = !fullscreen;
                                        },
                                        icon: (fullscreen)
                                            ? const Icon(
                                                Icons.fullscreen_exit_outlined,
                                              )
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
                  ),
                ),
              ],
            )
          : Column(
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
            ),
    );
  }
}
