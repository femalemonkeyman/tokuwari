import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:tokuwari/media/providers/anime/aes_decrypt.dart';
import 'package:tokuwari/models/anidata.dart';
import 'package:tokuwari/models/media_prov.dart';
import 'package:tokuwari/models/types.dart';

const String zoro = "https://hianime.to/";
const String mega = 'https://megacloud.blog/embed-2/v2/e-1/getSources?id=';

Provider zoroList(final AniData data) async {
  try {
    final malId = data.malid;
    final anisyncResponse = await Dio().get('$anisync/$malId');
    final zoroId = anisyncResponse.data['Sites']['Zoro'].keys.first;
    final episodeListResponse = await Dio().get(
      '${zoro}ajax/v2/episode/list/$zoroId',
      options: Options(responseType: ResponseType.plain),
    );
    final document = parse(jsonDecode(episodeListResponse.data)['html']);
    final episodeElements = document.getElementsByClassName('ssl-item  ep-item');
    return [
      for (final i in episodeElements)
        MediaProv(
          provider: 'zoro',
          provId: i.attributes['data-id']!,
          title: i.attributes['title']!,
          number: i.attributes['data-number']!,
          call: () => zoroInfo(i.attributes['data-id']!),
          //call: () => zoroInfo(i.attributes['href']!.split('watch/')[1]),
        ),
    ];
  } catch (e) {
    print(e);
    return [];
  }
}

// Future<Source> zoroInfo(final id) async {
//   final Options options = Options(responseType: ResponseType.plain);
//   String cat = 'sub';
//   print(id);
//   for (int attempt = 0; attempt < 2; attempt++) {
//     try {
//       final response = await Dio().get(
//         "https://aniwatch-ashen-six.vercel.app/aniwatch/episode-srcs?id=$id&server=vidstreaming&category=$cat",
//         options: options,
//       );
//       print(response.data);
//       final sources = jsonDecode(response.data);
//       sources['tracks'].removeWhere((element) => element['kind'] == 'thumbnails');
//       return Source(
//         qualities: {'default': sources['sources'][0]['url']},
//         subtitles: {for (Map i in sources['tracks']) i['label']: i['file']},
//         headers: {'origin': 'https://megacloud.club', 'referer': 'https://megacloud.club/'},
//       );
//     } on DioException catch (e) {
//       if (attempt == 0 && e.response?.statusCode == 504) {
//         cat = 'raw';
//         continue;
//       }
//       break;
//     } catch (err, stack) {
//       print(err);
//       print(stack);
//       break;
//     }
//   }

//   return const Source(qualities: {}, subtitles: {});
// }

Anime zoroInfo(final String id) async {
  final Options options = Options(responseType: ResponseType.plain);
  final dio = Dio();
  try {
    final serversResponse = await Dio().get('${zoro}ajax/v2/episode/servers?episodeId=$id', options: options);
    final String sId =
        parse(
          jsonDecode(serversResponse.data)['html'],
        ).getElementsByClassName("item server-item").first.attributes['data-id']!;
    final linkResponse = await dio.get('${zoro}ajax/v2/episode/sources?id=$sId', options: options);
    final String link = jsonDecode(linkResponse.data)['link'];
    final String segment = link.split('e-1/')[1].split('?')[0];
    final sourcesResponse = await dio.get('$mega$segment', options: options);
    final Map<String, dynamic> sources = jsonDecode(sourcesResponse.data);
    if (sources['encrypted']) {
      sources['sources'] = jsonDecode(await getSource(sources['sources']));
    }
    sources['tracks'].removeWhere((element) => element['kind'] == 'thumbnails');
    return Source(
      qualities: {'default': sources['sources'][0]['file']},
      subtitles: {for (Map i in sources['tracks']) i['label']: i['file']},
      headers: {'origin': 'https://megacloud.blog', 'referer': 'https://megacloud.blog/'},
    );
  } catch (err) {
    debugPrint(err.toString());
    return const Source(qualities: {}, subtitles: {});
  }
}

Future<String> getSource(String source) async {
  final key =
      (await Dio().get('https://raw.githubusercontent.com/itzzzme/megacloud-keys/refs/heads/main/key.txt')).data;
  return decrypt(source, key);
}
