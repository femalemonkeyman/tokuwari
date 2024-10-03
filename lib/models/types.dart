import 'package:tokuwari/models/chapter.dart';
import 'package:tokuwari/models/media_prov.dart';
import 'package:tokuwari/models/source.dart';

const String anisync = 'https://api.malsync.moe/mal/anime';

typedef Provider = Future<List<MediaProv>>;
typedef Call<T> = Future<T> Function();
typedef Anime = Future<Source>;
typedef Manga = Future<Chapter>;
