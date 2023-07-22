import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '/models/info_models.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';

const blank = Source(qualities: {}, subtitles: []);

class AniViewer extends StatefulWidget {
  final List<MediaProv> episodes;
  final int episode;

  const AniViewer({super.key, required this.episodes, required this.episode});

  @override
  State<StatefulWidget> createState() => AniViewerState();
}

class AniViewerState extends State<AniViewer> {
  static final Player player = Player();
  late final VideoController controller = VideoController(player);
  final List subTracks = [];
  late int currentEpisode = widget.episode;
  Source getMedia = blank;
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
        if (!Platform.isLinux) {
          await WakelockPlus.enable();
        }
        await play();
      },
    );
  }

  Future play() async {
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
        (player.platform as NativePlayer)
          ..setProperty("sub-auto", 'all')
          ..setProperty("sub-file-paths", dir.path)
          ..setProperty(
            'sid',
            '${getMedia.subtitles.lastIndexWhere(
                  (element) =>
                      element['lang']!.toLowerCase().contains('english'),
                ) + 1}',
          );
      }
      await player.open(
        Media(
          getMedia.qualities.values.first,
          httpHeaders: getMedia.headers ?? {},
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
        if (!Platform.isLinux) {
          await WakelockPlus.disable();
        }
        try {
          Directory(
            p.join((await getTemporaryDirectory()).path, 'anisubs'),
          ).deleteSync(
            recursive: true,
          );
        } catch (_) {}
        if (!Platform.isAndroid && !Platform.isIOS) {
          await windowManager.setFullScreen(false);
        }
        await player.stop();
      },
    );
    super.dispose();
  }

  @override
  Widget build(context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: (getMedia.qualities.isNotEmpty)
          ? Stack(
              children: [
                Video(
                  controller: controller,
                ),
                CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.arrowRight): () {
                      player.seek(
                        const Duration(seconds: 2),
                      );
                    },
                    const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                      player.seek(
                        const Duration(seconds: -2),
                      );
                    },
                    const SingleActivator(LogicalKeyboardKey.space): () {
                      player.playOrPause();
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
                                child: Row(
                                  children: [
                                    const BackButton(),
                                    const Spacer(),
                                    Text(
                                      "Episode ${widget.episodes[currentEpisode].number}",
                                    ),
                                    const Spacer(),
                                    if (widget.episodes[currentEpisode].title
                                        .isNotEmpty)
                                      Text(
                                        widget.episodes[currentEpisode].title,
                                      ),
                                    const Spacer(
                                      flex: 100,
                                    ),
                                    PopupMenuButton(
                                      itemBuilder: (context) {
                                        return [
                                          PopupMenuItem(
                                            child: const Text('Subtitles'),
                                            onTap: () => showBottomSheet(
                                              context: context,
                                              constraints:
                                                  BoxConstraints.tightFor(
                                                height: size.height / 2,
                                              ),
                                              builder: (context) => ListView(
                                                children: List.generate(
                                                  player.state.tracks.subtitle
                                                      .length,
                                                  (index) {
                                                    return ListTile(
                                                      title: Text(
                                                        // I miss you state sama
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
                                                height: size.height / 2,
                                              ),
                                              builder: (context) => ListView(
                                                children: List.generate(
                                                  player.state.tracks.video
                                                          .length -
                                                      2,
                                                  (index) {
                                                    return ListTile(
                                                      title: Text(
                                                        player
                                                                .state
                                                                .tracks
                                                                .video[
                                                                    index + 2]
                                                                .title ??
                                                            player
                                                                .state
                                                                .tracks
                                                                .video[
                                                                    index + 2]
                                                                .id,
                                                      ),
                                                      onTap: () {
                                                        player.setVideoTrack(
                                                          player.state.tracks
                                                              .video[index + 2],
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
                                                    getMedia = blank;
                                                  });
                                                  await play();
                                                },
                                          icon: const Icon(Icons.skip_previous),
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            await player.playOrPause();
                                            setState(() {});
                                          },
                                          icon: Icon((player.state.playing)
                                              ? Icons.pause
                                              : Icons.play_arrow),
                                        ),
                                        IconButton(
                                          onPressed: (currentEpisode ==
                                                  widget.episodes.length - 1)
                                              ? null
                                              : () async {
                                                  setState(() {
                                                    currentEpisode += 1;
                                                    getMedia = blank;
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
  late StreamSubscription position;
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
