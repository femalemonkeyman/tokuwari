import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tokuwari/models/anidata.dart';
import 'package:tokuwari/models/source.dart';
import 'package:tokuwari/viewers/Anime/anime_controller.dart';
import 'package:tokuwari/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

class AniViewer extends StatefulWidget {
  final AniData anime;
  final int episode;

  const AniViewer({super.key, required this.episode, required this.anime});

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
  late final CancelableOperation<Source> load = CancelableOperation.fromFuture(
    play(),
  );
  final bool isPhone = !Platform.isAndroid && !Platform.isIOS;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<Source> play() async {
    final Source media = await widget.anime.mediaProv[widget.episode].call!();
    if (media.qualities.isNotEmpty) {
      await player.open(
        Media(media.qualities.values.first, httpHeaders: media.headers ?? {}),
        play: false,
      );
      await controller.waitUntilFirstFrameRendered;
      await player.play();
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
    }
    return media;
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    load.cancel();
    await player.dispose();
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
                const SingleActivator(LogicalKeyboardKey.keyF):
                    () async => windowManager.setFullScreen(
                      !await windowManager.isFullScreen(),
                    ),
                const SingleActivator(LogicalKeyboardKey.escape):
                    () async => windowManager.setFullScreen(false),
                const SingleActivator(LogicalKeyboardKey.space):
                    () => player.playOrPause(),
                const SingleActivator(LogicalKeyboardKey.arrowRight): () {
                  player.seek(
                    player.state.position + const Duration(seconds: 3),
                  );
                },
                const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                  player.seek(
                    player.state.position - const Duration(seconds: 3),
                  );
                },
              },
              child: Focus(
                autofocus: true,
                child: Stack(
                  children: [
                    Video(
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
  final bool isPhone = !Platform.isAndroid && !Platform.isIOS;
  bool hide = true;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return AnimatedOpacity(
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
              AbsorbPointer(
                absorbing: hide,
                child: Row(
                  children: [
                    CloseButton(
                      onPressed: () {
                        windowManager.setFullScreen(false);
                        context.pop();
                      },
                    ),
                    const Spacer(),
                    Text(
                      "Episode ${widget.episode + 1} ${widget.anime.mediaProv[widget.episode].title}",
                      style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    const Spacer(),
                    const Spacer(flex: 100),
                    PopupMenuButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      itemBuilder:
                          (c) => [
                            if (widget.media.subtitles.isNotEmpty)
                              PopupMenuItem(
                                child: const Text('Subtitles'),
                                onTap:
                                    () => showModalBottomSheet(
                                      context: context,
                                      showDragHandle: true,
                                      builder:
                                          (context) => ListView(
                                            children: List.generate(
                                              widget.media.subtitles.length,
                                              (index) {
                                                return ListTile(
                                                  title: Text(
                                                    widget.media.subtitles.keys
                                                        .elementAt(index),
                                                  ),
                                                  onTap: () {
                                                    widget.player
                                                        .setSubtitleTrack(
                                                          SubtitleTrack.uri(
                                                            widget
                                                                .media
                                                                .subtitles
                                                                .values
                                                                .elementAt(
                                                                  index,
                                                                ),
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
                              onTap:
                                  () => showModalBottomSheet(
                                    showDragHandle: true,
                                    context: context,
                                    builder:
                                        (context) => ListView(
                                          children:
                                              (widget.media.qualities.length ==
                                                      1)
                                                  ? List.generate(
                                                    widget
                                                            .player
                                                            .state
                                                            .tracks
                                                            .video
                                                            .length -
                                                        2,
                                                    (i) => ListTile(
                                                      title: Text(
                                                        widget
                                                            .player
                                                            .state
                                                            .tracks
                                                            .video[i + 2]
                                                            .h
                                                            .toString(),
                                                      ),
                                                      onTap: () {
                                                        widget.player
                                                            .setVideoTrack(
                                                              widget
                                                                  .player
                                                                  .state
                                                                  .tracks
                                                                  .video[i + 2],
                                                            );
                                                        context.pop();
                                                      },
                                                    ),
                                                  )
                                                  : List.generate(
                                                    widget
                                                        .media
                                                        .qualities
                                                        .length,
                                                    (i) => ListTile(
                                                      title: Text(
                                                        widget
                                                            .media
                                                            .qualities
                                                            .keys
                                                            .elementAt(i),
                                                      ),
                                                      onTap: () async {
                                                        final subs =
                                                            widget
                                                                .player
                                                                .state
                                                                .track
                                                                .subtitle;
                                                        await widget.player.open(
                                                          Media(
                                                            widget
                                                                .media
                                                                .qualities
                                                                .values
                                                                .elementAt(i),
                                                            httpHeaders:
                                                                widget
                                                                    .media
                                                                    .headers,
                                                            start:
                                                                widget
                                                                    .player
                                                                    .state
                                                                    .position,
                                                          ),
                                                          play: false,
                                                        );
                                                        widget.player
                                                            .setSubtitleTrack(
                                                              subs,
                                                            );
                                                        await widget.player
                                                            .play();
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
              Expanded(
                child: GestureDetector(
                  onTap:
                      () => setState(() {
                        hide = !hide;
                      }),
                  onDoubleTapDown: (event) {
                    final pos = widget.player.state.position;
                    if (event.globalPosition.dx < width / 3)
                      widget.player.seek(pos - const Duration(seconds: 3));
                    if (event.globalPosition.dx > width / 1.5)
                      widget.player.seek(pos + const Duration(seconds: 3));
                  },
                ),
              ),
              AbsorbPointer(
                absorbing: hide,
                child: ProgressBar(player: widget.player),
              ),
              AbsorbPointer(
                absorbing: hide,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed:
                          (widget.episode == 0)
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
                    PlayButton(player: widget.player),
                    IconButton(
                      onPressed:
                          (widget.episode == widget.anime.mediaProv.length - 1)
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
                    VolumeSlider(player: widget.player),
                    const Spacer(),
                    if (isPhone) const FullScreenButton(),
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

class ProgressBar extends StatefulWidget {
  final Player player;

  const ProgressBar({super.key, required this.player});

  @override
  ProgressBarState createState() => ProgressBarState();
}

class ProgressBarState extends State<ProgressBar> {
  late final StreamSubscription<Duration> _positionSubscription;
  double _currentPosition = 0;

  @override
  void initState() {
    super.initState();

    _positionSubscription = widget.player.stream.position.listen((position) {
      setState(() {
        _currentPosition = position.inSeconds.toDouble();
      });
    });
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(Duration(seconds: _currentPosition.round()).label()),
        Expanded(
          child: Slider(
            focusNode: FocusNode(canRequestFocus: false),
            max: widget.player.state.duration.inSeconds.toDouble(),
            secondaryTrackValue:
                widget.player.state.buffer.inSeconds.toDouble(),
            divisions:
                widget.player.state.duration.inSeconds < 1
                    ? 1
                    : widget.player.state.duration.inSeconds,
            label: Duration(seconds: _currentPosition.toInt()).label(),
            value: _currentPosition,
            onChanged: (value) {
              setState(() {
                _currentPosition = value;
              });
            },
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
    builder:
        (context, snap) => IconButton(
          onPressed: () => player.playOrPause(),
          icon: Icon(
            (snap.requireData) ? Icons.pause : Icons.play_arrow_rounded,
          ),
        ),
  );
}

class VolumeSlider extends StatefulWidget {
  final Player player;
  const VolumeSlider({super.key, required this.player});

  @override
  State createState() => VolumeSliderState();
}

class VolumeSliderState extends State<VolumeSlider> {
  late double volume;

  @override
  void initState() {
    super.initState();
    volume = widget.player.state.volume;
  }

  @override
  Widget build(context) => Slider(
    min: 0,
    max: 100,
    divisions: 100,
    label: volume.round().toString(),
    value: volume,
    onChanged: (value) {
      setState(() {
        volume = value;
      });
      widget.player.setVolume(value);
    },
  );
}

class FullScreenButton extends StatelessWidget {
  const FullScreenButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        await windowManager.setFullScreen(!await windowManager.isFullScreen());
      },
      icon: Icon(Icons.fullscreen),
    );
  }
}
