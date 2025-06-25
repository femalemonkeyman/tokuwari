import 'package:tokuwari/media/providers/anime/aniwatch.dart';
import 'package:tokuwari/models/anidata.dart';

import 'anime/animepahe.dart';

import 'anime/hanime.dart';
import 'manga/mangadex.dart';

/// Must return of type [Provider]
final Map<String, List<Map<String, dynamic>>> providers = {
  'anime': [
    {'name': 'AnimePahe', 'data': (final AniData data) => paheList(data)},
    {'name': 'Aniwatch', 'data': (final AniData data) => zoroList(data)},
    {'name': 'Hanime', 'data': (final AniData data) => haniList(data)},
  ],
  'manga': [
    {'name': 'Mangadex', 'data': (final AniData data) => dexReader(data)},
  ],
};
