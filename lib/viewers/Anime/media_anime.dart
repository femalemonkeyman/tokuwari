import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tokuwari/discord_rpc.dart';
import 'package:tokuwari/widgets/loading.dart';
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
  final AniData anime;
  final int episode;

  const AniViewer({
    super.key,
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
    ),
  );
  late final VideoController controller = VideoController(
    player,
    configuration: const VideoControllerConfiguration(
      hwdec: 'auto-safe',
      androidAttachSurfaceAfterVideoParameters: false,
    ),
  );
  late final CancelableOperation<Source> load = CancelableOperation.fromFuture(play());
  final bool isPhone = !Platform.isAndroid && !Platform.isIOS;
  final DiscordRPC? discord = startRpc();

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
    // player.stream.log.listen((event) {
    //   print(event);
    // });
  }

  Future<Source> play() async {
    final Source media = await widget.anime.mediaProv[widget.episode].call!();
    if (media.qualities.isNotEmpty) {
      await player.open(
        Media(
          media.qualities.values.first,
          httpHeaders: media.headers ?? {},
        ),
        play: false,
      );
      if (media.subtitles.isNotEmpty) {
        await player.setSubtitleTrack(
          SubtitleTrack.uri(
            media.subtitles.entries
                .firstWhere(
                  (element) => element.key.toLowerCase().contains('eng'),
                )
                .value,
          ),
        );
      }
      if (discord != null) {
        discord!
          ..start(autoRegister: true)
          ..updatePresence(
            DiscordPresence(
              largeImageKey: widget.anime.image,
              details: "Watching: ${widget.anime.title}",
              state: "Episode: ${widget.episode + 1} / ${widget.anime.mediaProv.length}",
            ),
          );
      }
      await controller.waitUntilFirstFrameRendered;
      await player.play();
    }
    return media;
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    load.cancel();
    await player.dispose();
    discord?.clearPresence();
  }

  @override
  Widget build(context) {
    return Scaffold(
      body: FutureBuilder<Source>(
        future: load.value,
        builder: (context, snap) {
          if (snap.hasData && snap.requireData.qualities.isNotEmpty) {
            return CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.keyF): () async => windowManager.setFullScreen(
                      !await windowManager.isFullScreen(),
                    ),
                const SingleActivator(LogicalKeyboardKey.escape): () async => windowManager.setFullScreen(
                      false,
                    ),
                const SingleActivator(LogicalKeyboardKey.space): () => player.playOrPause(),
                const SingleActivator(LogicalKeyboardKey.arrowRight): () {
                  player.seek(player.state.position + const Duration(seconds: 3));
                },
                const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                  player.seek(player.state.position - const Duration(seconds: 3));
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
                      player: player,
                      media: snap.requireData,
                      episode: widget.episode,
                      anime: widget.anime,
                    ),
                  ],
                ),
              ),
            );
          }
          return const Loading();
        },
      ),
    );
  }
}

class Controls extends StatefulWidget {
  final Source media;
  final Player player;
  final int episode;
  final AniData anime;

  const Controls({
    super.key,
    required this.media,
    required this.player,
    required this.episode,
    required this.anime,
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
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(
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
                      if (widget.anime.mediaProv[widget.episode].title.isNotEmpty)
                        Text(
                          widget.anime.mediaProv[widget.episode].title,
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
                          if (widget.media.subtitles.isNotEmpty)
                            PopupMenuItem(
                              child: const Text('Subtitles'),
                              onTap: () => showModalBottomSheet(
                                context: context,
                                showDragHandle: true,
                                builder: (context) => ListView(
                                  children: List.generate(
                                    widget.media.subtitles.length,
                                    (index) {
                                      return ListTile(
                                        title: Text(
                                          widget.media.subtitles.keys.elementAt(index),
                                        ),
                                        onTap: () {
                                          widget.player.setSubtitleTrack(
                                            SubtitleTrack.uri(
                                              widget.media.subtitles.values.elementAt(index),
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
                                children: (widget.media.qualities.length == 1)
                                    ? List.generate(
                                        widget.player.state.tracks.video.length - 2,
                                        (i) => ListTile(
                                          title: Text(
                                            widget.player.state.tracks.video[i + 2].h.toString(),
                                          ),
                                          onTap: () {
                                            widget.player.setVideoTrack(
                                              widget.player.state.tracks.video[i + 2],
                                            );
                                            context.pop();
                                          },
                                        ),
                                      )
                                    : List.generate(
                                        widget.media.qualities.length,
                                        (i) => ListTile(
                                          title: Text(widget.media.qualities.keys.elementAt(i)),
                                          onTap: () async {
                                            final subs = widget.player.state.track.subtitle;
                                            await widget.player.open(
                                              Media(
                                                widget.media.qualities.values.elementAt(i),
                                                httpHeaders: widget.media.headers,
                                                start: widget.player.state.position,
                                              ),
                                              play: false,
                                            );
                                            widget.player.setSubtitleTrack(subs);
                                            await widget.player.play();
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
                  const Spacer(),
                  ProgressBar(player: widget.player),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: (widget.episode == 0)
                            ? null
                            : () => context.pushReplacement(
                                  '/anime/info/viewer',
                                  extra: {
                                    'index': widget.episode - 1,
                                    'data': widget.anime,
                                  },
                                ),
                        icon: const Icon(Icons.skip_previous),
                      ),
                      PlayButton(
                        player: widget.player,
                      ),
                      IconButton(
                        onPressed: (widget.episode == widget.anime.mediaProv.length - 1)
                            ? null
                            : () => context.pushReplacement(
                                  '/anime/info/viewer',
                                  extra: {
                                    'index': widget.episode + 1,
                                    'data': widget.anime,
                                  },
                                ),
                        icon: const Icon(Icons.skip_next),
                      ),
                      const Spacer(),
                      if (isPhone) const FullScreenButton(),
                    ],
                  ),
                ],
              ),
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
    return Row(
      children: [
        Text(Duration(seconds: spot.round()).label()),
        Expanded(
          child: Slider(
            focusNode: FocusNode(canRequestFocus: false),
            max: widget.player.state.duration.inSeconds.toDouble(),
            // label: Duration(seconds: spot.toInt()).label(),
            // divisions: widget.player.state.duration.inSeconds,
            secondaryTrackValue: widget.player.state.buffer.inSeconds.toDouble(),
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
    );
  }
}

class PlayButton extends StatelessWidget {
  final Player player;

  const PlayButton({super.key, required this.player});

  @override
  Widget build(context) => StreamBuilder<bool>(
        initialData: true,
        stream: player.stream.playing,
        builder: (context, snap) => IconButton(
          onPressed: () => player.playOrPause(),
          icon: Icon(
            (snap.requireData) ? Icons.pause : Icons.play_arrow_rounded,
          ),
        ),
      );
}

class FullScreenButton extends StatefulWidget {
  const FullScreenButton({super.key});

  @override
  State<StatefulWidget> createState() => FullScreenButtonState();
}

class FullScreenButtonState extends State<FullScreenButton> {
  @override
  Widget build(context) => FutureBuilder<bool>(
        initialData: false,
        future: windowManager.isFullScreen(),
        builder: (context, snap) => IconButton(
          onPressed: () async {
            windowManager.setFullScreen(!await windowManager.isFullScreen());
            setState(() {});
          },
          icon: snap.requireData ? const Icon(Icons.fullscreen_exit_rounded) : const Icon(Icons.fullscreen),
        ),
      );
}
