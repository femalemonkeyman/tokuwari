import 'package:dio/dio.dart';
import '../../../models/info_models.dart';

Future<List<MediaProv>> dexReader(final AniData data) async {
  const mangadex = "https://api.mangadex.org/manga";
  const String syncLink = 'https://api.malsync.moe/mal/manga/';
  try {
    final Map syncResponse = (await Dio().get('$syncLink${data.malid}')).data;
    final Map json = (await Dio().get(
      "$mangadex/${syncResponse['Sites']['Mangadex'].keys.first}/feed?limit=500&translatedLanguage[]=en&order[chapter]=asc",
    ))
        .data;
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

Future<List> dexPages(final String id) async {
  final List pages = [];
  final Response json = await Dio().get(
    "https://api.mangadex.org/at-home/server/$id",
  );
  for (var page in json.data['chapter']['data']) {
    pages.add(
      "https://uploads.mangadex.org/data/${json.data['chapter']['hash']}/$page",
    );
  }
  return pages;
}
