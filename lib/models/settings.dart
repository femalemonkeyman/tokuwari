import 'package:objectbox/objectbox.dart';

@Entity()
class Settings {
  int id = 0;
  bool isNsfw = false;
}
