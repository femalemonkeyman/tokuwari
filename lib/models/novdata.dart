import 'package:objectbox/objectbox.dart';

@Entity()
class NovData {
  @Id()
  int? id;
  @Index()
  final String type;
  final String title;
  final String image;
  final String path;
  NovData({required this.type, required this.title, required this.image, required this.path});
}
