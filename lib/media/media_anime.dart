import 'dart:async';
import 'package:async/async.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tokuwari/discord_rpc.dart';
import 'package:tokuwari_models/info_models.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

extension DurationExtension on Duration {
  /// Returns clamp of [Duration] between [min] and [max].
  Duration clamp(Duration min, Duration max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  /// Returns a [String] representation of [Duration].
  String label({Duration? reference}) {
    reference ??= this;
    if (reference > const Duration(days: 1)) {
      final days = inDays.toString().padLeft(3, '0');
      final hours = (inHours - (inDays * 24)).toString().padLeft(2, '0');
      final minutes = (inMinutes - (inHours * 60)).toString().padLeft(2, '0');
      final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$days:$hours:$minutes:$seconds';
    } else if (reference > const Duration(hours: 1)) {
      final hours = inHours.toString().padLeft(2, '0');
      final minutes = (inMinutes - (inHours * 60)).toString().padLeft(2, '0');
      final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    } else {
      final minutes = inMinutes.toString().padLeft(2, '0');
      final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }
  }
}

final GlobalKey<VideoState> vKey = GlobalKey<VideoState>();

class AniViewer extends StatefulWidget {
  final List<MediaProv> episodes;
  final AniData anime;
  final int episode;

  const AniViewer({
    super.key,
    required this.episodes,
    required this.episode,
    required this.anime,
  });

  @override
  State<StatefulWidget> createState() => AniViewerState();
}

class AniViewerState extends State<AniViewer> {
  final Player player = Player(
      configuration: const PlayerConfiguration(
    //logLevel: MPVLogLevel.v,
    vo: 'gpu',
  ));
  DiscordRPC? discord = startRpc();
  late final VideoController controller = VideoController(
    player,
    configuration: const VideoControllerConfiguration(hwdec: 'auto-safe'),
  );
  late final CancelableOperation load = CancelableOperation.fromFuture(play());
  Source media = const Source(qualities: {}, subtitles: {});

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
    load.value;
    // player.stream.log.listen((event) {
    //   print(event);
    // });
  }

  Future<void> play() async {
    media = await widget.episodes[widget.episode].call!();
    if (media.qualities.isNotEmpty) {
      await player.open(
        Media(
          media.qualities.values.first,
          httpHeaders: media.headers ?? {},
        ),
        play: false,
      );
      await setSubtitles();
      if (discord != null) {
        discord!
          ..start(autoRegister: true)
          ..updatePresence(
            DiscordPresence(
              largeImageKey: widget.anime.image,
              details: "Watching: ${widget.episodes[widget.episode].title}",
              state:
                  "Episode: ${widget.episode + 1} / ${widget.episodes.length}",
            ),
          );
      }
      await controller.waitUntilFirstFrameRendered;
      await player.play();
      setState(() {});
    }
  }

  Future<void> setSubtitles() async {
    if (media.subtitles.isNotEmpty) {
      player.setSubtitleTrack(
        SubtitleTrack.uri(
          media.subtitles.entries
              .firstWhere(
                (element) => element.key.toLowerCase().contains('eng'),
              )
              .value,
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations(
      [],
    );
    load.cancel();
    await player.dispose();
    discord?.clearPresence();
  }

  @override
  Widget build(context) {
    return Scaffold(
      body: (media.qualities.isNotEmpty)
          ? CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.keyF): () async =>
                    windowManager.setFullScreen(
                      !await windowManager.isFullScreen(),
                    ),
                const SingleActivator(LogicalKeyboardKey.space): () =>
                    player.playOrPause(),
                const SingleActivator(LogicalKeyboardKey.arrowRight): () {
                  player
                      .seek(player.state.position + const Duration(seconds: 3));
                },
                const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                  player
                      .seek(player.state.position - const Duration(seconds: 3));
                }
              },
              child: Focus(
                autofocus: true,
                child: Stack(
                  children: [
                    Video(
                      key: vKey,
                      controller: controller,
                      controls: NoVideoControls,
                      pauseUponEnteringBackgroundMode: false,
                    ),
                    Controls(
                      topbar: Positioned(
                        top: 10,
                        left: 20,
                        right: 20,
                        child: Row(
                          children: [
                            BackButton(
                              onPressed: () {
                                windowManager.setFullScreen(false);
                                context.pop();
                              },
                            ),
                            const Spacer(),
                            Text(
                              "Episode ${widget.episode + 1}",
                              style: const TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                            const Spacer(),
                            if (widget
                                .episodes[widget.episode].title.isNotEmpty)
                              Text(
                                widget.episodes[widget.episode].title,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                ),
                              ),
                            const Spacer(
                              flex: 100,
                            ),
                            PopupMenuButton(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              itemBuilder: (c) => [
                                if (media.subtitles.isNotEmpty)
                                  PopupMenuItem(
                                    child: const Text('Subtitles'),
                                    onTap: () => showModalBottomSheet(
                                      context: context,
                                      showDragHandle: true,
                                      builder: (context) => ListView(
                                        children: List.generate(
                                          media.subtitles.length,
                                          (index) {
                                            return ListTile(
                                              title: Text(
                                                media.subtitles.keys
                                                    .elementAt(index),
                                              ),
                                              onTap: () {
                                                player.setSubtitleTrack(
                                                  SubtitleTrack.uri(
                                                    media.subtitles.values
                                                        .elementAt(index),
                                                  ),
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
                                  onTap: () => showModalBottomSheet(
                                    showDragHandle: true,
                                    context: context,
                                    builder: (context) => ListView(
                                      children: (media.qualities.length == 1)
                                          ? List.generate(
                                              player.state.tracks.video.length,
                                              (i) => ListTile(
                                                    title: Text(
                                                      player.state.tracks
                                                          .video[i].h
                                                          .toString(),
                                                    ),
                                                    onTap: () {
                                                      player.setVideoTrack(
                                                        player.state.tracks
                                                            .video[i],
                                                      );
                                                      context.pop();
                                                    },
                                                  ))
                                          : List.generate(
                                              media.qualities.length,
                                              (i) => ListTile(
                                                title: Text(media.qualities.keys
                                                    .elementAt(i)),
                                                onTap: () async {
                                                  await (player.platform
                                                          as NativePlayer)
                                                      .setProperty(
                                                    "start",
                                                    player.state.position
                                                        .toString(),
                                                  );
                                                  await player.open(
                                                    Media(
                                                      media.qualities.values
                                                          .elementAt(i),
                                                      httpHeaders:
                                                          media.headers,
                                                    ),
                                                    play: false,
                                                  );
                                                  await setSubtitles();
                                                  await player.play();
                                                  if (context.mounted) {
                                                    context.pop();
                                                  }
                                                },
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      progressbar: Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: ProgressBar(
                          player: player,
                        ),
                      ),
                      bottombar: Positioned(
                        bottom: 10,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: (widget.episode == 0)
                                  ? null
                                  : () => context.pushReplacement(
                                        '/anime/info/viewer',
                                        extra: {
                                          'index': widget.episode - 1,
                                          'contents': widget.episodes,
                                          'data': widget.anime,
                                        },
                                      ),
                              icon: const Icon(Icons.skip_previous),
                            ),
                            PlayButton(
                              player: player,
                            ),
                            IconButton(
                              onPressed:
                                  (widget.episode == widget.episodes.length - 1)
                                      ? null
                                      : () => context.pushReplacement(
                                            '/anime/info/viewer',
                                            extra: {
                                              'index': widget.episode + 1,
                                              'contents': widget.episodes,
                                              'data': widget.anime,
                                            },
                                          ),
                              icon: const Icon(Icons.skip_next),
                            ),
                            const Spacer(),
                            const FullScreenButton(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => context.pop(),
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

class Controls extends StatefulWidget {
  final Widget topbar;
  final Widget progressbar;
  final Widget bottombar;

  const Controls({
    super.key,
    required this.topbar,
    required this.progressbar,
    required this.bottombar,
  });

  @override
  State createState() => ControlsState();
}

class ControlsState extends State<Controls> {
  late final RestartableTimer enter = RestartableTimer(
    const Duration(seconds: 3),
    () => setState(
      () {
        hide = true;
      },
    ),
  );
  bool hide = true;

  @override
  void dispose() {
    enter.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
        onHover: (_) => setState(() {
          hide = false;
          // vKey.currentState!
          //     .setSubtitleViewPadding(EdgeInsets.only(bottom: 50));
          enter.reset();
        }),
        child: AnimatedOpacity(
          opacity: (hide) ? 0 : 1,
          duration: const Duration(milliseconds: 500),
          child: DecoratedBox(
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
            child: Stack(
              children: [
                widget.topbar,
                widget.progressbar,
                widget.bottombar,
              ],
            ),
          ),
        ),
      );
}

class ProgressBar extends StatefulWidget {
  final Player player;

  const ProgressBar({super.key, required this.player});

  @override
  State createState() => ProgressBarState();
}

class ProgressBarState extends State<ProgressBar> {
  late final StreamSubscription position;
  double spot = 0;

  @override
  void initState() {
    position = widget.player.stream.position.listen((event) => setState(() {
          spot = event.inSeconds.toDouble();
        }));
    super.initState();
  }

  @override
  void dispose() {
    position.cancel();
    super.dispose();
  }

  @override
  Widget build(context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, right: 20, left: 20),
      child: Row(
        children: [
          Text(Duration(seconds: spot.round()).label()),
          Expanded(
            child: Slider(
              focusNode: FocusNode(canRequestFocus: false),
              max: widget.player.state.duration.inSeconds.toDouble(),
              // label: Duration(seconds: spot.toInt()).label(),
              // divisions: widget.player.state.duration.inSeconds,
              secondaryTrackValue:
                  widget.player.state.buffer.inSeconds.toDouble(),
              value: spot,
              onChanged: (value) => setState(
                () => spot = value,
              ),
              onChangeStart: (_) => widget.player.pause(),
              onChangeEnd: (value) async {
                await widget.player.seek(Duration(seconds: value.toInt()));
                widget.player.play();
              },
            ),
          ),
          Text(widget.player.state.duration.label()),
        ],
      ),
    );
  }
}

class PlayButton extends StatefulWidget {
  final Player player;

  const PlayButton({super.key, required this.player});

  @override
  State createState() => PlayButtonState();
}

class PlayButtonState extends State<PlayButton> {
  late final StreamSubscription playing;

  @override
  void initState() {
    playing = widget.player.stream.playing.listen(
      (_) => setState(() {}),
    );
    super.initState();
  }

  @override
  void dispose() {
    playing.cancel();
    super.dispose();
  }

  @override
  Widget build(context) => IconButton(
        onPressed: () => setState(() {
          widget.player.playOrPause();
        }),
        icon: Icon(
          (widget.player.state.playing)
              ? Icons.pause
              : Icons.play_arrow_rounded,
        ),
      );
}

class FullScreenButton extends StatelessWidget {
  const FullScreenButton({super.key});

  @override
  Widget build(context) => IconButton(
        onPressed: () async {
          windowManager.setFullScreen(!await windowManager.isFullScreen());
        },
        icon: const Icon(Icons.fullscreen),
      );
}
