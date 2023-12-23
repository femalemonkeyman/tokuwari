import 'package:tokuwari/media/providers/anime/anitaku.dart';
import 'package:tokuwari/media/providers/anime/aniwatch.dart';
import 'package:tokuwari_models/info_models.dart';

import 'anime/animepahe.dart';

import 'anime/hanime.dart';
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
      'name': 'Anitaku',
      'data': (final AniData data) => gogoList(data),
    },
    //RIP
    // {
    //   'name': 'Marin',
    //   'data': (final AniData data) => marinList(data),
    // },
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
