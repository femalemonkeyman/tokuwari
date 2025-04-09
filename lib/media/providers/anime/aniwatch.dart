import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:tokuwari/models/anidata.dart';
import 'package:tokuwari/models/media_prov.dart';
import 'package:tokuwari/models/source.dart';
import 'package:tokuwari/models/types.dart';

const String zoro = "https://hianime.to/";
const String mega = 'https://megacloud.tv/embed-2/ajax/e-1/getSources?id=';
int retries = 0;

Provider zoroList(final AniData data) async {
  try {
    return [
      for (Element i in parse(
        jsonDecode(
          await Dio()
              .get('$anisync/${data.malid}')
              .then(
                (data) async => Dio().get(
                  '${zoro}ajax/v2/episode/list/${data.data['Sites']['Zoro'].keys.first}',
                  options: Options(responseType: ResponseType.plain),
                ),
              )
              .then((value) => value.data),
        )['html'],
      ).getElementsByClassName('ssl-item  ep-item'))
        MediaProv(
          provider: 'zoro',
          provId: i.attributes['data-id']!,
          title: i.attributes['title']!,
          number: i.attributes['data-number']!,
          call: () => zoroInfo(i.attributes['href']!.split('watch/')[1]),
        ),
    ];
  } catch (e) {
    print(e);
    return [];
  }
}

Anime zoroInfo(final id) async {
  final Options options = Options(responseType: ResponseType.plain);
  try {
    final sources = await Dio()
        .get(
          "https://anime-api-five-sigma.vercel.app/aniwatch/episode-srcs?id=$id&server=vidstreaming&category=sub",
          options: options,
        )
        .then((data) => jsonDecode(data.data));
    print(sources);
    sources['tracks'].removeWhere((element) => element['kind'] == 'thumbnails');
    return Source(
      qualities: {'default': sources['sources'][0]['url']},
      subtitles: {for (Map i in sources['tracks']) i['label']: i['file']},
      headers: {
        'origin': 'https://megacloud.club',
        'referer': 'https://megacloud.club/',
      },
    );
  } catch (err, stack) {
    print(err);
    print(stack);
    return const Source(qualities: {}, subtitles: {});
  }
}

// Anime zoroInfo(final id) async {
//   print(id);
//   final Options options = Options(responseType: ResponseType.plain);
//   try {
//     final String sId = await Dio()
//         .get(
//           '${zoro}ajax/v2/episode/servers?episodeId=$id',
//           options: options,
//         )
//         .then(
//           (value) => parse(jsonDecode(value.data)['html'])
//               .getElementsByClassName("item server-item")
//               .first
//               .attributes['data-id']!,
//         );
//     final String link = await Dio()
//         .get(
//       '${zoro}ajax/v2/episode/sources?id=$sId',
//       options: options,
//     )
//         .then(
//       (value) {
//         return jsonDecode(value.data)['link'];
//       },
//     );
//     print(link);
//     final Map<String, dynamic> sources = jsonDecode(
//       await Dio().get('$mega${link.split('e-1/')[1].split('?')[0]}', options: options).then(
//             (value) => value.data,
//           ),
//     );
//     print('$mega${link.split('e-1/')[1].split('?')[0]}');
//     print(sources);
//     if (sources['encrypted']) {
//       sources['sources'] = jsonDecode(
//         await getSource(
//           sources['sources'],
//           (retries == 1) ? true : false,
//         ),
//       );
//     }
//     retries = 0;
//     sources['tracks'].removeWhere((element) => element['kind'] != 'captions');
//     return Source(
//       qualities: {
//         'default': sources['sources'][0]['file'],
//       },
//       subtitles: {
//         for (Map i in sources['tracks']) i['label']: i['file'],
//       },
//     );
//   } catch (err, _) {
//     if (retries == 0) {
//       retries++;
//       return await zoroInfo(id);
//     } else {
//       //print(_);
//       return const Source(qualities: {}, subtitles: {});
//     }
//   }
// }
