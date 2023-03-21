import 'package:dio/dio.dart';

//Consumet
Future<List> mediaList(id) async {
  String link = "https://api.consumet.org/meta/anilist/info/$id?provider=zoro";
  var json = await Dio().get(link);
  return List.generate(
    json.data['episodes'].length,
    (index) {
      return {
        "id": json.data['episodes'][index]['id'],
        "title": json.data['episodes'][index]['title'],
        "number": "Episode: ${json.data['episodes'][index]['number']}",
        "description": json.data['episodes'][index]['description']
      };
    },
  );
}

Future<Map> mediaInfo(id) async {
  String link = "https://api.consumet.org/meta/anilist/watch/$id?provider=zoro";
  var json = await Dio().get(link);
  return json.data;
}
// End Consumet