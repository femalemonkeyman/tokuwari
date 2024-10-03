import 'package:isar/isar.dart';

part 'novdata.g.dart';

@collection
class NovData {
  @index
  final String type;
  final String title;
  final String image;
  @id
  final String path;
  const NovData({
    required this.type,
    required this.title,
    required this.image,
    required this.path,
  });
}
