import 'package:dio/dio.dart';

import '../manga/manga.dart';

Future<List> dexReader(id) async {
  var json = await Dio().get(
    "${mangadex}manga/$id/feed?limit=500&translatedLanguage[]=en&order[chapter]=asc",
  );
  //print(json.data);
  // for (var i in json.data['volumes'].values) {
  //   if (i['chapters'] is List) {
  //     i['chapters'] = {
  //       i['chapters'][0]['chapter']: i['chapters'][0],
  //     };
  //   }
  //   for (var j in i['chapters'].values) {
  //     chapters.add(j);
  //   }
  // }
  return List.generate(
    json.data['data'].length,
    (index) {
      return {
        'id': json.data['data'][index]['id'],
        "title": json.data['data'][index]['attributes']['title'] ?? "",
        "number":
            "${(json.data['data'][index]['attributes']['volume'] != null) ? "Vol: ${json.data['data'][index]['attributes']['volume']}" : ""} Ch: ${json.data['data'][index]['attributes']['chapter']}",
      };
    },
  );
}
