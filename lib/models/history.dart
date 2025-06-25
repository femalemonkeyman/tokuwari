import 'package:objectbox/objectbox.dart';

@Entity()
class History {
  @Id()
  int id;

  /// mediaId should be the mediaId from an [AniData] object which is the id from anilist
  final String mediaId;
  final String title;
  final String image;
  final String type;
  bool finished = false;

  /// Should be for keeping the position of a video
  int? secondsWatched;

  /// If manga we only need to track the last page the user was on
  int? page;

  History({this.id = 0, required this.title, required this.image, required this.mediaId, required this.type});
}
