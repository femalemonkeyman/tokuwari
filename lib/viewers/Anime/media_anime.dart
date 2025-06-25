import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tokuwari/models/anidata.dart';
import 'package:tokuwari/models/types.dart';
import 'package:tokuwari/viewers/Anime/anime_extensions.dart';
import 'package:tokuwari/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

class PlayProv extends InheritedWidget {
  final Player player;

  const PlayProv({required this.player, required super.child, super.key});

  static PlayProv of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<PlayProv>()!;

  @override
  bool updateShouldNotify(PlayProv oldWidget) => player != oldWidget.player;
}

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
  late final CancelableOperation<Source> load = CancelableOperation.fromFuture(play());
  final bool isPhone = !Platform.isAndroid && !Platform.isIOS;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  Future<Source> play() async {
    final Source media = await widget.anime.mediaProv[widget.episode].call!();
    if (media.qualities.isNotEmpty) {
      await player.open(Media(media.qualities.values.first, httpHeaders: media.headers ?? {}), play: false);
      await controller.waitUntilFirstFrameRendered;
      await player.play();
      if (media.subtitles.isNotEmpty) {
        await player.setSubtitleTrack(
          SubtitleTrack.uri(
            media.subtitles.entries.firstWhere((element) => element.key.toLowerCase().contains('eng')).value,
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
    return PlayProv(
      player: player,
      child: Scaffold(
        body: FutureBuilder<Source>(
          future: load.value,
          builder: (context, snap) {
            if (snap.hasData && snap.requireData.qualities.isNotEmpty) {
              return CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.keyF):
                      () async => windowManager.setFullScreen(!await windowManager.isFullScreen()),
                  const SingleActivator(LogicalKeyboardKey.escape): () async => windowManager.setFullScreen(false),
                  const SingleActivator(LogicalKeyboardKey.space): () => player.playOrPause(),
                  const SingleActivator(LogicalKeyboardKey.arrowRight): () {
                    player.seek(player.state.position + const Duration(seconds: 3));
                  },
                  const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                    player.seek(player.state.position - const Duration(seconds: 3));
                  },
                },
                child: Focus(
                  autofocus: true,
                  child: Stack(
                    children: [
                      Video(controller: controller, controls: NoVideoControls, pauseUponEnteringBackgroundMode: false),
                      Controls(media: snap.requireData, episode: widget.episode, anime: widget.anime),
                    ],
                  ),
                ),
              );
            }
            return const Loading();
          },
        ),
      ),
    );
  }
}

class Controls extends StatefulWidget {
  final Source media;
  final int episode;
  final AniData anime;

  const Controls({super.key, required this.media, required this.episode, required this.anime});

  @override
  State createState() => ControlsState();
}

class ControlsState extends State<Controls> {
  final bool isPhone = !Platform.isAndroid && !Platform.isIOS;
  bool hide = true;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final media = widget.media;
    final player = PlayProv.of(context).player;
    final episode = widget.episode;
    final anime = widget.anime;

    return AnimatedOpacity(
      opacity: hide ? 0 : 1,
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
                    Expanded(
                      child: Text(
                        "Episode ${episode + 1} ${anime.mediaProv[episode].title}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    PopupMenuButton(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      itemBuilder:
                          (c) => [
                            if (media.subtitles.isNotEmpty)
                              PopupMenuItem(
                                child: const Text('Subtitles'),
                                onTap:
                                    () => showModalBottomSheet(
                                      context: context,
                                      showDragHandle: true,
                                      builder:
                                          (_) => ListView(
                                            children: [
                                              for (final entry in media.subtitles.entries)
                                                ListTile(
                                                  title: Text(entry.key),
                                                  onTap: () {
                                                    player.setSubtitleTrack(SubtitleTrack.uri(entry.value));
                                                    context.pop();
                                                  },
                                                ),
                                            ],
                                          ),
                                    ),
                              ),
                            PopupMenuItem(
                              child: const Text('Quality'),
                              onTap:
                                  () => showModalBottomSheet(
                                    showDragHandle: true,
                                    context: context,
                                    builder: (_) {
                                      final items =
                                          media.qualities.length == 1
                                              ? List.generate(
                                                player.state.tracks.video.length - 2,
                                                (i) => ListTile(
                                                  title: Text(player.state.tracks.video[i + 2].h.toString()),
                                                  onTap: () {
                                                    player.setVideoTrack(player.state.tracks.video[i + 2]);
                                                    context.pop();
                                                  },
                                                ),
                                              )
                                              : List.generate(
                                                media.qualities.length,
                                                (i) => ListTile(
                                                  title: Text(media.qualities.keys.elementAt(i)),
                                                  onTap: () async {
                                                    final subs = player.state.track.subtitle;
                                                    await player.open(
                                                      Media(
                                                        media.qualities.values.elementAt(i),
                                                        httpHeaders: media.headers,
                                                        start: player.state.position,
                                                      ),
                                                      play: false,
                                                    );
                                                    player.setSubtitleTrack(subs);
                                                    await player.play();
                                                    if (context.mounted) context.pop();
                                                  },
                                                ),
                                              );
                                      return ListView(children: items);
                                    },
                                  ),
                            ),
                          ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => hide = !hide),
                  onDoubleTapDown: (event) {
                    final pos = player.state.position;
                    final dx = event.globalPosition.dx;
                    if (dx < width / 3) player.seek(pos - const Duration(seconds: 3));
                    if (dx > width / 1.5) player.seek(pos + const Duration(seconds: 3));
                  },
                ),
              ),
              AbsorbPointer(absorbing: hide, child: ProgressBar()),
              AbsorbPointer(
                absorbing: hide,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed:
                          episode == 0
                              ? null
                              : () => context.pushReplacement(
                                '/anime/info/viewer',
                                extra: {'index': episode - 1, 'data': anime},
                              ),
                      icon: const Icon(Icons.skip_previous),
                    ),
                    PlayButton(),
                    IconButton(
                      onPressed:
                          episode == anime.mediaProv.length - 1
                              ? null
                              : () => context.pushReplacement(
                                '/anime/info/viewer',
                                extra: {'index': episode + 1, 'data': anime},
                              ),
                      icon: const Icon(Icons.skip_next),
                    ),
                    VolumeSlider(),
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
  const ProgressBar({super.key});

  @override
  ProgressBarState createState() => ProgressBarState();
}

class ProgressBarState extends State<ProgressBar> {
  late final Player player;
  StreamSubscription<Duration>? _positionSubscription;
  double _currentPosition = 0;
  bool _hovering = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    player = PlayProv.of(context).player;
    _positionSubscription?.cancel();
    _positionSubscription = player.stream.position.listen((position) {
      if (!_hovering) setState(() => _currentPosition = position.inSeconds.toDouble());
    });
  }

  @override
  void dispose() {
    _positionSubscription!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = player.state.duration.inSeconds.toDouble();
    final buffer = player.state.buffer.inSeconds.toDouble();

    return Row(
      children: [
        Text(Duration(seconds: _currentPosition.round()).label()),
        Expanded(
          child: Slider(
            focusNode: FocusNode(canRequestFocus: false),
            max: duration,
            secondaryTrackValue: buffer,
            divisions: duration < 1 ? 1 : duration.toInt(),
            label: Duration(seconds: _currentPosition.toInt()).label(),
            value: _currentPosition.clamp(0, duration),
            onChanged: (value) {
              setState(() {
                _currentPosition = value;
              });
            },
            onChangeStart: (_) {
              _hovering = true;
              player.pause();
            },
            onChangeEnd: (value) async {
              _hovering = false;
              await player.seek(Duration(seconds: value.toInt()));
              player.play();
            },
          ),
        ),
        Text(player.state.duration.label()),
      ],
    );
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({super.key});

  @override
  Widget build(BuildContext context) {
    final player = PlayProv.of(context).player;

    return StreamBuilder<bool>(
      initialData: true,
      stream: player.stream.playing,
      builder: (context, snap) {
        final isPlaying = snap.data ?? true;
        return IconButton(
          onPressed: player.playOrPause,
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow_rounded),
        );
      },
    );
  }
}

class VolumeSlider extends StatefulWidget {
  const VolumeSlider({super.key});

  @override
  State createState() => VolumeSliderState();
}

class VolumeSliderState extends State<VolumeSlider> {
  late Player player;
  late double volume;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    player = PlayProv.of(context).player;
    volume = player.state.volume;
  }

  @override
  Widget build(BuildContext context) => Slider(
    min: 0,
    max: 100,
    divisions: 100,
    label: volume.round().toString(),
    value: volume,
    onChanged: (value) {
      setState(() {
        volume = value;
      });
      player.setVolume(value);
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
      icon: const Icon(Icons.fullscreen),
    );
  }
}
