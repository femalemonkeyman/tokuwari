import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:tokuwari/models/anidata.dart';
import 'package:tokuwari/models/media_prov.dart';
import 'package:tokuwari/models/source.dart';
import 'package:tokuwari/models/types.dart';

Provider haniList(final AniData data) async {
  try {
    Map json =
        (await Dio().post(
          "https://search.htv-services.com/",
          data: jsonEncode({
            "search_text": data.title
                .split(" ")
                .take(2)
                .join(' ')
                .replaceAll(RegExp('[^A-Za-z0-9- !]'), ''),
            "tags": [],
            "tags-mode": "AND",
            "brands": [],
            "blacklist": [],
            "order_by": "",
            "ordering": "",
            "page": 0,
          }),
        )).data;
    if (json['nbHits'] > 0) {
      final List requests = await Future.wait([
        for (Map i in jsonDecode(json['hits']))
          if (data.title
                  .bestMatch([i['name'], ...i['titles']])
                  .bestMatch
                  .rating! >
              0.52)
            Dio().get("https://hanime.tv/api/v8/video?id=${i['id']}"),
      ]);
      return [
        for (Response i in requests)
          MediaProv(
            provider: 'hanime',
            provId: '',
            title: i.data['hentai_video']['name'],
            number: i.data['hentai_video']['slug'].split('-').last.toString(),
            call:
                () => Future(
                  () => Source(
                    qualities: {
                      "default":
                          i.data['videos_manifest']['servers'][0]['streams'][1]['url'],
                    },
                    subtitles: {},
                  ),
                ),
          ),
      ];
    }
  } catch (_) {}
  return [];
}
