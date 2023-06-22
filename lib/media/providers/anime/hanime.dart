import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:string_similarity/string_similarity.dart';
import '../../../models/info_models.dart';

Future<List<MediaProv>> haniList(final AniData data) async {
  Response json = await Dio().post(
    "https://search.htv-services.com/",
    data: jsonEncode(
      {
        "search_text": (
          (data.title.split(" ").length > 3)
              ? data.title.split(" ").getRange(0, 3).join(" ")
              : data.title,
        ).toString().replaceAll(RegExp('[^A-Za-z0-9 -]'), ''),
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
    final List videos = [];
    for (Map i in results) {
      final Response v = await Dio().get(
        "https://hanime.tv/api/v8/video?id=${i['id']}",
      );
      if (i['name'].toString().similarityTo(data.title) > 0.2) {
        videos.add(v.data);
      }
    }
    return List.generate(
      videos.length,
      (index) {
        return MediaProv(
          provider: 'hanime',
          provId: '',
          title: (videos[index])['hentai_video']['name'],
          number: (index + 1).toString(),
          call: () => Source(qualities: {
            "default": videos[index]['videos_manifest']['servers'][0]['streams']
                [1]['url'],
          }, subtitles: []),
        );
      },
    );
  }
  return [];
}
