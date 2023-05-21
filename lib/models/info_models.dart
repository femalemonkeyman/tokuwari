import 'package:isar/isar.dart';

part 'info_models.g.dart';

@collection
class AniData {
  final Id id = Isar.autoIncrement;
  final String type;
  final String? mediaId;
  final String? malid;
  final String title;
  final String? description;
  final String image;
  final String? score;
  final String? count;
  final List<String>? tags;
  AniData({
    required this.type,
    this.mediaId,
    this.malid,
    required this.title,
    this.description,
    required this.image,
    this.count,
    this.score,
    this.tags,
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
  final Function? call;
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
