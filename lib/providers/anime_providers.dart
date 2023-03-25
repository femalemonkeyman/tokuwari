import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:string_similarity/string_similarity.dart';

//Consumet
Future<List?> mediaList(id) async {
  Response json = await Dio().get(
    "https://api.consumet.org/meta/anilist/info/$id?provider=zoro",
  );
  return (json.data['episodes'].isEmpty)
      ? null
      : List.generate(
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

Future<Map?> mediaInfo(id) async {
  try {
    Response json = await Dio().get(
      "https://api.consumet.org/meta/anilist/watch/$id?provider=zoro",
    );
    return json.data;
  } catch (e) {
    return null;
  }
}
// End Consumet

//Begin Hanime
Future<List?> haniList(String name) async {
  //name.split(pattern).getRange(0, 3);
  Response json = await Dio().post(
    "https://search.htv-services.com/",
    data: jsonEncode(
      {
        "search_text": (name.split(" ").length > 3)
            ? name.split(" ").getRange(0, 3).join(" ").replaceAll(":", "")
            : name,
        // "${name.split(" ")[0]} ${name.split(" ")[1]} ${name.split(" ")[2]}"
        //     .replaceAll(":", ""),
        "tags": [],
        "tags-mode": "AND",
        "brands": [],
        "blacklist": [],
        "order_by": "",
        "ordering": "",
        "page": 0
      },
    ),
  );
  if (json.data['nbHits'] > 0) {
    final List results = jsonDecode(json.data['hits']);

    List videos = [];

    for (var i in results) {
      Response v = await Dio().get(
        "https://hanime.tv/api/v8/video?id=${i['id']}",
      );
      videos.add(v.data);
    }

    return List.generate(
      videos.length,
      (index) {
        return {
          "title": (videos[index])['hentai_video']['name'],
          "number": "Episode: ${index + 1}",
          "sources": [
            {
              "url": videos[index]['videos_manifest']['servers'][0]['streams']
                  [1]['url']
            },
          ],
        };
      },
    );
  }
  return null;
}
