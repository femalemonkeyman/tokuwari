import 'dart:async';
import 'package:go_router/go_router.dart';
import '/models/info_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

const Source blank = Source(qualities: {}, subtitles: {});

void setSubtitles(final Source media, final Player player) async {
  if (media.subtitles.isNotEmpty) {
    await player.stream.buffer.first;
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

  Future<void> play() async {
    media = await widget.episodes[currentEpisode].call!();
    if (media.qualities.isNotEmpty) {
      await player.open(
        Media(
          media.qualities.values.first,
          httpHeaders: media.headers ?? {},
        ),
      );
      setState(
        () {
          setSubtitles(media, player);
        },
      );
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    Future.microtask(
      () async {
        await player.dispose();
        await const MethodChannel('com.alexmercerind/media_kit_video')
            .invokeMethod(
          'Utils.ExitNativeFullscreen',
        );
      },
    );
    super.dispose();
  }

  @override
  Widget build(context) {
    final MaterialDesktopVideoControlsThemeData desktop =
        MaterialDesktopVideoControlsThemeData(
      toggleFullscreenOnDoublePress: false,
      automaticallyImplySkipNextButton: false,
      automaticallyImplySkipPreviousButton: false,
      topButtonBar: [
        MaterialDesktopCustomButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const Spacer(),
        Text(
          "Episode ${widget.episodes[currentEpisode].number}",
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        const Spacer(),
        if (widget.episodes[currentEpisode].title.isNotEmpty)
          Text(
            widget.episodes[currentEpisode].title,
            style: const TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        const Spacer(
          flex: 100,
        ),
        PopupMenuButton(
          color: const Color.fromARGB(255, 255, 255, 255),
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
                builder: (context) => ListView(
                  children: (media.qualities.length == 1)
                      ? List.generate(
                          player.state.tracks.video.length - 2,
                          (index) {
                            return ListTile(
                              title: Text(
                                player.state.tracks.video[index + 2].h
                                    .toString(),
                              ),
                              onTap: () {
                                player.setVideoTrack(
                                  player.state.tracks.video[index + 2],
                                );
                                context.pop();
                              },
                            );
                          },
                        )
                      : List.generate(
                          media.qualities.length,
                          (index) {
                            return ListTile(
                              title:
                                  Text(media.qualities.keys.elementAt(index)),
                              onTap: () {
                                Future.microtask(
                                  () async {
                                    final current =
                                        await player.stream.position.first;
                                    player.open(
                                      Media(
                                        media.qualities.values.elementAt(index),
                                        httpHeaders: media.headers,
                                      ),
                                      play: false,
                                    );
                                    await player.stream.buffer.first;
                                    setSubtitles(media, player);
                                    player
                                      ..seek(current)
                                      ..play();
                                  },
                                );
                                context.pop();
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
      bottomButtonBar: [
        MaterialDesktopCustomButton(
          onPressed: (currentEpisode == 0)
              ? () {}
              : () async {
                  setState(() {
                    currentEpisode -= 1;
                    player.stop();
                  });
                  await play();
                },
          icon: const Icon(Icons.skip_previous),
        ),
        const MaterialDesktopPlayOrPauseButton(),
        MaterialDesktopCustomButton(
          onPressed: (currentEpisode == widget.episodes.length - 1)
              ? () {}
              : () async {
                  setState(() {
                    currentEpisode += 1;
                    player.stop();
                  });
                  await play();
                },
          icon: const Icon(Icons.skip_next),
        ),
        const MaterialDesktopVolumeButton(),
        const MaterialDesktopPositionIndicator(),
        const Spacer(),
        MaterialDesktopCustomButton(
          onPressed: () => setState(() {
            if (fullscreen) {
              const MethodChannel('com.alexmercerind/media_kit_video')
                  .invokeMethod(
                'Utils.ExitNativeFullscreen',
              );
            } else {
              const MethodChannel('com.alexmercerind/media_kit_video')
                  .invokeMethod(
                'Utils.EnterNativeFullscreen',
              );
            }
            fullscreen = !fullscreen;
          }),
          icon: (fullscreen)
              ? const Icon(Icons.fullscreen_exit)
              : const Icon(Icons.fullscreen),
        ),
      ],
    );
    final MaterialVideoControlsThemeData mobile =
        MaterialVideoControlsThemeData(
      seekBarMargin: const EdgeInsets.all(20),
      seekBarHeight: 6,
      bottomButtonBarMargin: const EdgeInsets.all(20),
      automaticallyImplySkipNextButton: false,
      automaticallyImplySkipPreviousButton: false,
      topButtonBar: [
        MaterialCustomButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        const Spacer(),
        Text(
          "Episode ${widget.episodes[currentEpisode].number}",
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        const Spacer(),
        if (widget.episodes[currentEpisode].title.isNotEmpty)
          Text(
            widget.episodes[currentEpisode].title,
            style: const TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        const Spacer(
          flex: 100,
        ),
        PopupMenuButton(
          color: const Color.fromARGB(255, 255, 255, 255),
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
                builder: (context) => ListView(
                  children: (media.qualities.length == 1)
                      ? List.generate(
                          player.state.tracks.video.length - 2,
                          (index) {
                            return ListTile(
                              title: Text(
                                player.state.tracks.video[index + 2].h
                                    .toString(),
                              ),
                              onTap: () {
                                player.setVideoTrack(
                                  player.state.tracks.video[index + 2],
                                );
                                context.pop();
                              },
                            );
                          },
                        )
                      : List.generate(
                          media.qualities.length,
                          (index) {
                            return ListTile(
                              title:
                                  Text(media.qualities.keys.elementAt(index)),
                              onTap: () {
                                Future.microtask(
                                  () async {
                                    final current =
                                        await player.stream.position.first;
                                    player.open(
                                      Media(
                                        media.qualities.values.elementAt(index),
                                        httpHeaders: media.headers,
                                      ),
                                      play: false,
                                    );
                                    await player.stream.buffer.first;
                                    setSubtitles(media, player);
                                    player
                                      ..seek(current)
                                      ..play();
                                  },
                                );
                                context.pop();
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
      bottomButtonBar: const [
        MaterialPositionIndicator(),
      ],
      primaryButtonBar: [
        const Spacer(flex: 2),
        MaterialCustomButton(
          onPressed: (currentEpisode == 0)
              ? () {}
              : () async {
                  setState(() {
                    currentEpisode -= 1;
                    player.stop();
                  });
                  await play();
                },
          icon: const Icon(Icons.skip_previous),
        ),
        const Spacer(),
        const MaterialPlayOrPauseButton(iconSize: 48.0),
        const Spacer(),
        MaterialCustomButton(
          onPressed: (currentEpisode == widget.episodes.length - 1)
              ? () {}
              : () async {
                  setState(() {
                    currentEpisode += 1;
                    player.stop();
                  });
                  await play();
                },
          icon: const Icon(Icons.skip_next),
        ),
        const Spacer(flex: 2)
      ],
    );

    return Scaffold(
      body: (media.qualities.isNotEmpty)
          ? MaterialDesktopVideoControlsTheme(
              normal: desktop,
              fullscreen: desktop,
              child: MaterialVideoControlsTheme(
                normal: mobile,
                fullscreen: mobile,
                child: Video(
                  controller: controller,
                  pauseUponEnteringBackgroundMode: false,
                  controls: AdaptiveVideoControls,
                ),
              ),
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
