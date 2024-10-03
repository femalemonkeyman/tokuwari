import 'package:isar/isar.dart';
import 'package:tokuwari/models/types.dart';

class MediaProv {
  late final String id = "$provider/$provId";
  final String provider;
  final String provId;
  final String title;
  final String number;
  @ignore

  ///Call must be a function for the simple reason if it's not it will run when
  ///the widget is built
  final Call? call;

  MediaProv({
    required this.provider,
    required this.provId,
    required this.title,
    required this.number,
    this.call,
  });
}
