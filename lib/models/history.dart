import 'package:isar/isar.dart';

part 'history.g.dart';

@collection
class History {
  @Id()
  final int id;

  /// mediaId should be the mediaId from an [AniData] object which is the id from anilist
  final String mediaId;
  final String title;
  final String image;
  final String type;

  /// Should be a [Duration] for keeping the position of a video or the page
  int? watched;
  int? page;

  History({
    required this.title,
    required this.image,
    required this.id,
    required this.mediaId,
    required this.type,
  });
}
