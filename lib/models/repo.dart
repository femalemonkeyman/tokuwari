import 'package:path_provider/path_provider.dart';
import 'package:tokuwari/models/anidata.dart';
import 'package:tokuwari/models/history.dart';
import 'package:tokuwari/models/novdata.dart';
import 'package:tokuwari/models/objectbox.g.dart';
import 'package:tokuwari/models/settings.dart';

export 'package:tokuwari/models/objectbox.g.dart';

class Repo {
  late final Store store;

  Repo._(this.store);

  static Repo? _instance;

  static Future<void> init() async {
    if (_instance == null) {
      final dir = await getApplicationDocumentsDirectory();
      final store = await openStore(directory: "${dir.path}/.tokuwari");
      _instance = Repo._(store);
    }
  }

  static Repo get i {
    if (_instance != null) {
      return _instance!;
    }
    throw Exception("oops");
  }

  Box<AniData> get anidata => store.box<AniData>();
  Box<NovData> get novdata => store.box<NovData>();
  Box<History> get history => store.box<History>();
  Box<Settings> get settings => store.box<Settings>();
}

extension Help<T> on QueryBuilder<T> {
  Stream<List<T>> assign() => watch(triggerImmediately: true).map((query) => query.find());
}
