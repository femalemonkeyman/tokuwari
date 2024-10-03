import 'dart:io';

import 'package:async/async.dart';
import 'package:media_kit/media_kit.dart';
import 'package:tokuwari/models/anidata.dart';
import 'package:tokuwari/models/source.dart';

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
    int days = inDays;
    int hours = inHours - (days * 24);
    int minutes = inMinutes - (inHours * 60);
    int seconds = inSeconds - (inMinutes * 60);
    if (reference > const Duration(days: 1)) {
      return '${days.toString().padLeft(3, '0')}:'
          '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else if (reference > const Duration(hours: 1)) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }
}

class AnimeController {
  final Player player = Player(
    configuration: const PlayerConfiguration(
      //logLevel: MPVLogLevel.v,
      vo: 'gpu',
    ),
  );
  late final CancelableOperation<Source> load = CancelableOperation.fromFuture(play());
  final bool isPhone = !Platform.isAndroid && !Platform.isIOS;
  final AniData anime;
  int episode;

  AnimeController(this.anime, this.episode);

  Future<Source> play() async {
    final Source media = await anime.mediaProv[episode].call!();
    if (media.qualities.isNotEmpty) {
      await player.open(
        Media(
          media.qualities.values.first,
          httpHeaders: media.headers ?? {},
        ),
        play: false,
      );
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

  pause() {}
  next() {}
  previous() {}

  void dispose() {
    player.dispose();
    load.cancel();
  }
}
