import 'package:tokuwari/media/providers/anime/animepahe.dart';
import 'package:tokuwari/media/providers/anime/marin.dart';
import 'package:tokuwari/models/info_models.dart';

import 'anime/hanime.dart';
import 'anime/aniwatch.dart';
import 'manga/mangadex.dart';

/// Must return of type [Provider]
final Map<String, List<Map<String, dynamic>>> providers = {
  'anime': [
    {
      'name': 'Aniwatch',
      'data': (final AniData data) => zoroList(data),
    },
    {
      'name': 'AnimePahe',
      'data': (final AniData data) => paheList(data),
    },
    {
      'name': 'Marin',
      'data': (final AniData data) => marinList(data),
    },
    {
      'name': 'Hanime',
      'data': (final AniData data) => haniList(data),
    },
  ],
  'manga': [
    {
      'name': 'Mangadex',
      'data': (final AniData data) => dexReader(data),
    },
  ],
};
