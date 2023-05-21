import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/info_models.dart';

Future<List<MediaProv>> dexReader(id) async {
  const mangadex = "https://api.mangadex.org/";
  const String syncLink =
      'https://raw.githubusercontent.com/MALSync/MAL-Sync-Backup/master/data/anilist/manga/';
  final Map syncResponse = jsonDecode(
    (await Dio().get('$syncLink$id.json')).data,
  );
  final Map json = (await Dio().get(
    "${mangadex}manga/${syncResponse['Pages']['Mangadex'].keys.first}/feed?limit=500&translatedLanguage[]=en&order[chapter]=asc",
  ))
      .data;
  return List.generate(
    json['data'].length,
    (index) {
      return MediaProv(
          provider: 'mangadex',
          provId: json['data'][index]['id'],
          title: json['data'][index]['attributes']['title'] ?? "",
          number:
              "${(json['data'][index]['attributes']['volume'] != null) ? "Vol: ${json['data'][index]['attributes']['volume']}" : ""} Ch: ${json['data'][index]['attributes']['chapter']}");
    },
  );
}
