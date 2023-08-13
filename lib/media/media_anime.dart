import 'dart:async';
import 'package:go_router/go_router.dart';
import '/models/info_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';

const Source blank = Source(qualities: {}, subtitles: {});

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
  late int currentEpisode = widget.episode;
  Source media = blank;
  bool fullscreen = false;
  bool show = false;

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
        await play();
      },
    );
  }

  Future play() async {
    media = await widget.episodes[currentEpisode].call!();
    if (media.qualities.isNotEmpty) {
      await player.open(
        Media(
          media.qualities.values.first,
          httpHeaders: media.headers ?? {},
        ),
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    Future.microtask(
      () async {
        if (!Platform.isAndroid && !Platform.isIOS) {
          await windowManager.setFullScreen(false);
        }
        await player.dispose();
      },
    );
    super.dispose();
  }

  @override
  Widget build(context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: (media.qualities.isNotEmpty)
          ? Stack(
              children: [
                Video(
                  controller: controller,
                  pauseUponEnteringBackgroundMode: false,
                ),
                CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.arrowRight):
                        () async {
                      await player.seek(
                        player.state.position + const Duration(seconds: 5),
                      );
                    },
                    const SingleActivator(LogicalKeyboardKey.arrowLeft):
                        () async {
                      await player.seek(
                        player.state.position - const Duration(seconds: 5),
                      );
                    },
                    const SingleActivator(LogicalKeyboardKey.space): () async {
                      await player.playOrPause();
                    },
                  },
                  child: Focus(
                    autofocus: true,
                    child: GestureDetector(
                      onTap: () => setState(
                        () => show = !show,
                      ),
                      onDoubleTapDown: (details) =>
                          switch (details.localPosition.dx > size.width / 2) {
                        true => player.seek(
                            player.state.position + const Duration(seconds: 5),
                          ),
                        false => player.seek(
                            player.state.position - const Duration(seconds: 5),
                          ),
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
                                child: TopBar(
                                  currentEpisode: currentEpisode,
                                  episodes: widget.episodes,
                                  media: media,
                                  player: player,
                                  size: size,
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Column(
                                  children: [
                                    ProgressBar(player: player),
                                    Row(
                                      children: [
                                        const Spacer(),
                                        IconButton(
                                          onPressed: (currentEpisode == 0)
                                              ? null
                                              : () async {
                                                  setState(() {
                                                    currentEpisode -= 1;
                                                    media = blank;
                                                  });
                                                  await play();
                                                },
                                          icon: const Icon(Icons.skip_previous),
                                        ),
                                        StreamBuilder(
                                          stream: player.stream.playing,
                                          initialData: true,
                                          builder: (context, snapshot) {
                                            return IconButton(
                                              onPressed: () async {
                                                await player.playOrPause();
                                              },
                                              icon: Icon((snapshot.data == true)
                                                  ? Icons.pause
                                                  : Icons.play_arrow),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          onPressed: (currentEpisode ==
                                                  widget.episodes.length - 1)
                                              ? null
                                              : () async {
                                                  setState(() {
                                                    currentEpisode += 1;
                                                    media = blank;
                                                  });
                                                  await play();
                                                },
                                          icon: const Icon(Icons.skip_next),
                                        ),
                                        Slider(
                                          min: 0,
                                          max: 100,
                                          divisions: 100,
                                          label: player.state.volume
                                              .round()
                                              .toString(),
                                          value: player.state.volume,
                                          onChanged: (value) =>
                                              Future.microtask(
                                            () async {
                                              await player.setVolume(value);
                                              setState(() {});
                                            },
                                          ),
                                        ),
                                        const Spacer(
                                          flex: 50,
                                        ),
                                        if (!Platform.isAndroid &&
                                            !Platform.isIOS)
                                          IconButton(
                                            iconSize: 50,
                                            onPressed: () async {
                                              fullscreen = !fullscreen;
                                              WindowManager.instance
                                                  .setFullScreen(fullscreen);
                                            },
                                            icon: Icon(
                                              (fullscreen)
                                                  ? Icons.fullscreen_exit
                                                  : Icons.fullscreen,
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
    position = widget.player.stream.position
        .listen((event) => update(event.inSeconds.toDouble()));
    super.initState();
  }

  @override
  void dispose() {
    position.cancel();
    super.dispose();
  }

  void update(update) {
    setState(() {
      spot = update;
    });
  }

  @override
  Widget build(context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, right: 20, left: 20),
      child: Row(
        children: [
          Text(Duration(seconds: spot.round()).toString().split('.')[0]),
          Expanded(
            child: Slider(
              min: 0,
              max: widget.player.state.duration.inSeconds.toDouble(),
              secondaryTrackValue:
                  widget.player.state.buffer.inSeconds.toDouble(),
              value: spot,
              onChanged: (value) {
                update(value);
              },
              onChangeStart: (value) => position.pause(),
              onChangeEnd: (value) {
                widget.player.seek(Duration(seconds: value.toInt()));
                position.resume();
              },
            ),
          ),
          Text(
              widget.player.state.duration.toString().toString().split('.')[0]),
        ],
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  final int currentEpisode;
  final List<MediaProv> episodes;
  final Source media;
  final Player player;
  final Size size;

  const TopBar({
    super.key,
    required this.currentEpisode,
    required this.episodes,
    required this.player,
    required this.size,
    required this.media,
  });

  @override
  Widget build(context) => Row(
        children: [
          const BackButton(),
          const Spacer(),
          Text(
            "Episode ${episodes[currentEpisode].number}",
          ),
          const Spacer(),
          if (episodes[currentEpisode].title.isNotEmpty)
            Text(
              episodes[currentEpisode].title,
            ),
          const Spacer(
            flex: 100,
          ),
          PopupMenuButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            itemBuilder: (context) => [
              if (media.subtitles.isNotEmpty)
                PopupMenuItem(
                  child: const Text('Subtitles'),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    constraints: BoxConstraints.tightFor(
                      height: size.height / 2,
                    ),
                    showDragHandle: true,
                    builder: (context) => ListView(
                      children: List.generate(
                        media.subtitles.length,
                        (index) {
                          return ListTile(
                            title: Text(
                              media.subtitles.keys.elementAt(index),
                            ),
                            onTap: () {
                              player.setSubtitleTrack(
                                SubtitleTrack.uri(
                                  media.subtitles.values.elementAt(index),
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
                  constraints: BoxConstraints.tightFor(
                    height: size.height / 2,
                  ),
                  builder: (context) => ListView(
                    children: List.generate(
                      // player.state.tracks.video.length - 2,
                      media.qualities.length,
                      (index) {
                        return ListTile(
                          title: Text(media.qualities.keys.elementAt(index)),
                          onTap: () async {
                            final current = await player.stream.buffer.first;
                            print(current);
                            await player.open(
                              Media(
                                media.qualities.values.elementAt(index),
                                httpHeaders: media.headers,
                              ),
                            );
                            await player.seek(current);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
}
