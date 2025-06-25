import 'package:tokuwari/models/chapter.dart';
import 'package:tokuwari/models/media_prov.dart';

const String anisync = 'https://api.malsync.moe/mal/anime';

typedef Provider = Future<List<MediaProv>>;
typedef Call<T> = Future<T> Function();
typedef Anime = Future<Source>;
typedef Manga = Future<Chapter>;

class Source {
  /// The map should be in the format of
  /// ```dart
  /// {quality_name: link_to_file}
  /// ```
  /// If there exists only one link and that link is hls and has multiple
  /// qualities please name the key as hls so the media player knows, otherwise
  /// name it default.
  final Map<String, String> qualities;

  ///Subtitles is a map consisting of the language and the url
  ///```dart
  /// [{lang: url}]
  ///```
  final Map<String, String> subtitles;

  /// Any headers you might need for the request
  final Map<String, String>? headers;

  const Source({required this.qualities, required this.subtitles, this.headers});
}
