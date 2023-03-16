import 'package:dio/dio.dart';

import '../manga/manga.dart';

Future<List> dexReader(id) async {
  List chapters = [];
  var json = await Dio().get(
    "${mangadex}manga/$id/aggregate?translatedLanguage[]=en",
  );
  for (var i in json.data['volumes'].values) {
    if (i['chapters'] is List) {
      i['chapters'] = {
        i['chapters'][0]['chapter']: i['chapters'][0],
      };
    }
    for (var j in i['chapters'].values) {
      chapters.add(j);
    }
  }
  return chapters;
}
