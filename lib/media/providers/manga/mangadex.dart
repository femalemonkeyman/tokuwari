import 'package:dio/dio.dart';
import 'package:tokuwari/models/anidata.dart';
import 'package:tokuwari/models/chapter.dart';
import 'package:tokuwari/models/media_prov.dart';
import 'package:tokuwari/models/types.dart';

Provider dexReader(final AniData data) async {
  const mangadex = "https://api.mangadex.org/manga";
  const String syncLink = 'https://api.malsync.moe/mal/manga/';
  try {
    final json = await Dio().get('$syncLink${data.malid}').then(
          (malsync) async => await Dio()
              .get(
                "$mangadex/${malsync.data['Sites']['Mangadex'].keys.first}/feed?limit=500&translatedLanguage[]=en&order[chapter]=asc&includeEmptyPages=0",
              )
              .then((value) => value.data),
        );
    return List.generate(
      json['data'].length,
      (index) {
        return MediaProv(
          provider: 'mangadex',
          provId: json['data'][index]['id'],
          title: json['data'][index]['attributes']['title'] ?? "",
          number: json['data'][index]['attributes']['chapter'],
          call: () => dexPages(json['data'][index]['id']),
        );
      },
    );
  } catch (_) {
    return [];
  }
}

Manga dexPages(final String id) async {
  final Response json = await Dio().get(
    "https://api.mangadex.org/at-home/server/$id",
  );
  return Chapter(
    pages: [
      for (final page in json.data['chapter']['data'])
        "https://uploads.mangadex.org/data/${json.data['chapter']['hash']}/$page",
    ],
  );
}
