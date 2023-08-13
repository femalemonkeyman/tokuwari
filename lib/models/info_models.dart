import 'package:isar/isar.dart';

part 'info_models.g.dart';

const String malsync = 'https://api.malsync.moe/mal/anime';

typedef Provider = Future<List<MediaProv>>;
typedef Call<T> = Future<T> Function();
typedef Anime = Future<Source>;

@collection
class AniData {
  final Id id = Isar.autoIncrement;
  final String type;
  final String mediaId;
  final int? malid;
  final String title;
  final String description;
  final String status;
  final String image;
  final String score;
  final String count;
  final List<String> tags;
  @ignore
  bool dub = false;

  AniData({
    required this.type,
    required this.mediaId,
    required this.malid,
    required this.title,
    required this.description,
    required this.status,
    required this.image,
    required this.count,
    required this.score,
    required this.tags,
  });

  AniData.fromJson(Map<String, dynamic> json, this.type)
      : malid = json['idMal'],
        mediaId = json['id'].toString(),
        description = (json['description'] ?? "")
            .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' '),
        status = json['status'].toString(),
        title = json['title']['romaji'].toString(),
        image = json['coverImage']['extraLarge'],
        count = (json['episodes'] ?? json['chapters'] ?? "n/a").toString(),
        score = (json['averageScore'] ?? "n/a").toString(),
        tags = List.generate(
          json['tags'].length,
          (tagIndex) {
            return json['tags'][tagIndex]['name'];
          },
        );
}

@collection
class NovData {
  final Id id = Isar.autoIncrement;
  final String type;
  final String title;
  final String image;
  final String path;
  const NovData({
    required this.type,
    required this.title,
    required this.image,
    required this.path,
  });
}

@collection
class MediaProv {
  final Id id = Isar.autoIncrement;
  final String provider;
  final String provId;
  final String title;
  final String number;
  @ignore

  ///Call must be a function for the simple reason if it's not it will run when
  ///the widget is built
  final Call? call;

  /// Whether the media is completed
  bool consumed;

  ///The last known position of the media after consumption has started
  String? position;

  MediaProv({
    required this.provider,
    required this.provId,
    required this.title,
    required this.number,
    this.call,
    this.consumed = false,
  });
}

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

  const Source({
    required this.qualities,
    required this.subtitles,
    this.headers,
  });
}
