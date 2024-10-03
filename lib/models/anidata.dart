import 'package:isar/isar.dart';
import 'package:tokuwari/models/media_prov.dart';

part 'anidata.g.dart';

@collection
class AniData {
  @Id()
  int id;
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

  /// The list of Episodes or chapters found for this media
  @ignore
  final List<MediaProv> mediaProv = [];

  AniData({
    required this.id,
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

  AniData.fromJson(Map<String, dynamic> json, this.type, {this.id = 0})
      : malid = json['idMal'],
        mediaId = json['id'].toString(),
        description = (json['description'] ?? "").replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' '),
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
