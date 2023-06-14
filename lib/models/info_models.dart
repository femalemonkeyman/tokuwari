import 'package:isar/isar.dart';

part 'info_models.g.dart';

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
  NovData({
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
  final Function()? call;
  bool watched;
  String? position;

  MediaProv({
    required this.provider,
    required this.provId,
    required this.title,
    required this.number,
    this.call,
    this.watched = false,
  });
}

class Source {
  final Map<String, String> qualities;
  final List<Map<String, String>> subtitles;
  final Map<String, String>? headers;

  Source({
    required this.qualities,
    required this.subtitles,
    this.headers,
  });
}
