import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tokuwari/discord_rpc.dart';
import 'package:tokuwari_models/info_models.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

final GlobalKey<VideoState> videoKey = GlobalKey<VideoState>();

class AniViewer extends StatefulWidget {
  final List<MediaProv> episodes;
  final int episode;
  final AniData anime;

  const AniViewer(
      {super.key,
      required this.episodes,
      required this.episode,
      required this.anime});

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
  late final VideoController controller = VideoController(player,
      configuration: const VideoControllerConfiguration(hwdec: 'auto-safe'));
  late int currentEpisode = widget.episode;
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
    Future.microtask(
      () async => await play(),
    );
    player.stream.log.listen((event) {
      print(event);
    });
  }

  Future<void> play() async {
    media = await widget.episodes[currentEpisode].call!();
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
              details: "Watching: ${widget.anime.title}",
              state:
                  "Episode: ${currentEpisode + 1} / ${widget.episodes.length}",
            ),
          );
      }
      await controller.waitUntilFirstFrameRendered;
      setState(() {
        player.play();
      });
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
    await videoKey.currentState?.exitFullscreen();
    await player.dispose();
    discord?.clearPresence();
  }

  @override
  Widget build(context) {
    final desktop = MaterialDesktopVideoControlsThemeData(
      automaticallyImplySkipNextButton: false,
      automaticallyImplySkipPreviousButton: false,
      topButtonBar: [
        MaterialDesktopCustomButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () async {
            await videoKey.currentState!.exitFullscreen();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        const Spacer(),
        Text(
          "Episode ${widget.episodes[currentEpisode].number}",
        ),
        const Spacer(),
        if (widget.episodes[currentEpisode].title.isNotEmpty)
          Text(
            widget.episodes[currentEpisode].title,
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
                      ? [
                          for (int i = 2;
                              i < player.state.tracks.video.length;
                              i++)
                            ListTile(
                              title: Text(
                                player.state.tracks.video[i].h.toString(),
                              ),
                              onTap: () {
                                player.setVideoTrack(
                                  player.state.tracks.video[i],
                                );
                                context.pop();
                              },
                            )
                        ]
                      : [
                          for (int i = 0; i < media.qualities.length; i++)
                            ListTile(
                              title: Text(media.qualities.keys.elementAt(i)),
                              onTap: () async {
                                final current = player.state.position;
                                await player.open(
                                  Media(
                                    media.qualities.values.elementAt(i),
                                    httpHeaders: media.headers,
                                  ),
                                  play: false,
                                );
                                await setSubtitles();
                                await player
                                    .seek(player.state.position + current);
                                await player.play();
                                if (context.mounted) {
                                  context.pop();
                                }
                              },
                            )
                        ],
                ),
              ),
            ),
          ],
        ),
      ],
      bottomButtonBar: [
        IconButton(
          onPressed: (currentEpisode == 0)
              ? null
              : () => context.pushReplacement(
                    '/anime/info/viewer',
                    extra: {
                      'index': currentEpisode - 1,
                      'contents': widget.episodes,
                      'data': widget.anime,
                    },
                  ),
          icon: const Icon(Icons.skip_previous),
        ),
        const MaterialDesktopPlayOrPauseButton(),
        IconButton(
          onPressed: (currentEpisode == widget.episodes.length - 1)
              ? null
              : () => context.pushReplacement(
                    '/anime/info/viewer',
                    extra: {
                      'index': currentEpisode + 1,
                      'contents': widget.episodes,
                      'data': widget.anime,
                    },
                  ),
          icon: const Icon(Icons.skip_next),
        ),
        const MaterialDesktopVolumeButton(),
        const MaterialDesktopPositionIndicator(),
        const Spacer(),
        const MaterialDesktopFullscreenButton(),
      ],
    );
    final mobile = MaterialVideoControlsThemeData(
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
                      ? [
                          for (int i = 2;
                              i < player.state.tracks.video.length;
                              i++)
                            ListTile(
                              title: Text(
                                player.state.tracks.video[i].h.toString(),
                              ),
                              onTap: () {
                                player.setVideoTrack(
                                  player.state.tracks.video[i],
                                );
                                context.pop();
                              },
                            )
                        ]
                      : [
                          for (int i = 0; i < media.qualities.length; i++)
                            ListTile(
                              title: Text(media.qualities.keys.elementAt(i)),
                              onTap: () async {
                                final current = player.state.position;
                                await player.open(
                                  Media(
                                    media.qualities.values.elementAt(i),
                                    httpHeaders: media.headers,
                                  ),
                                  play: false,
                                );
                                await setSubtitles();
                                await player
                                    .seek(player.state.position + current);
                                await player.play();
                                if (context.mounted) {
                                  context.pop();
                                }
                              },
                            )
                        ],
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
        IconButton(
          onPressed: (currentEpisode == 0)
              ? null
              : () => context.pushReplacement(
                    '/anime/info/viewer',
                    extra: {
                      'index': currentEpisode - 1,
                      'contents': widget.episodes,
                      'data': widget.anime,
                    },
                  ),
          icon: const Icon(Icons.skip_previous),
        ),
        const Spacer(),
        const MaterialPlayOrPauseButton(iconSize: 48.0),
        const Spacer(),
        IconButton(
          onPressed: (currentEpisode == widget.episodes.length - 1)
              ? null
              : () => context.pushReplacement(
                    '/anime/info/viewer',
                    extra: {
                      'index': currentEpisode + 1,
                      'contents': widget.episodes,
                      'data': widget.anime,
                    },
                  ),
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
                  key: videoKey,
                  controller: controller,
                  pauseUponEnteringBackgroundMode: false,
                  onEnterFullscreen: () async => await const MethodChannel(
                          'com.alexmercerind/media_kit_video')
                      .invokeMethod(
                    'Utils.EnterNativeFullscreen',
                  ),
                  onExitFullscreen: () async => await const MethodChannel(
                          'com.alexmercerind/media_kit_video')
                      .invokeMethod(
                    'Utils.ExitNativeFullscreen',
                  ),
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
