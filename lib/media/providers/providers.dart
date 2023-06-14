import 'package:tokuwari/media/providers/anime/animepahe.dart';
import 'package:tokuwari/models/info_models.dart';

import 'anime/hanime.dart';
import 'anime/zoro.dart';
import 'manga/mangadex.dart';

final Map<String, List<Map<String, dynamic>>> providers = {
  'anime': [
    {
      'name': 'Zoro',
      'data': (final AniData data) => zoroList(data),
    },
    {
      'name': 'AnimePahe',
      'data': (final AniData data) => paheList(data),
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
