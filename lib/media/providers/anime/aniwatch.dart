import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:key/key.dart';
import 'package:tokuwari_models/info_models.dart';

const String zoro = "https://aniwatch.to/";
const String mega = 'https://megacloud.tv/embed-2/ajax/e-1/getSources?id=';
int retries = 0;

Provider zoroList(final AniData data) async {
  try {
    return [
      for (Element i in parse(jsonDecode(await Dio()
              .get(
                '$anisync/${data.malid}',
              )
              .then(
                (data) async => Dio().get(
                  '${zoro}ajax/v2/episode/list/${data.data['Sites']['Zoro'].keys.first}',
                  options: Options(
                    responseType: ResponseType.plain,
                  ),
                ),
              )
              .then((value) => value.data))['html'])
          .getElementsByClassName('ssl-item  ep-item'))
        MediaProv(
          provider: 'zoro',
          provId: i.attributes['data-id']!,
          title: i.attributes['title']!,
          number: i.attributes['data-number']!,
          call: () => zoroInfo(i.attributes['data-id']),
        ),
    ];
  } catch (e) {
    print(e);
    return [];
  }
}

Anime zoroInfo(final id) async {
  final Options options = Options(responseType: ResponseType.plain);
  final String sId = await Dio()
      .get(
        '${zoro}ajax/v2/episode/servers?episodeId=$id',
        options: options,
      )
      .then(
        (value) => parse(jsonDecode(value.data)['html'])
            .getElementsByClassName("item server-item")
            .firstWhere(
              (element) => element.text.contains('Vid'),
            )
            .attributes['data-id']!,
      );
  try {
    final String link = await Dio()
        .get(
      '${zoro}ajax/v2/episode/sources?id=$sId',
      options: options,
    )
        .then(
      (value) {
        return jsonDecode(value.data)['link'];
      },
    );
    final Map<String, dynamic> sources = jsonDecode(
      await Dio().get('$mega${link.split('e-1/')[1].split('?')[0]}', options: options).then(
            (value) => value.data,
          ),
    );
    if (sources['encrypted']) {
      sources['sources'] = jsonDecode(
        await getSource(
          sources['sources'],
          (retries == 1) ? true : false,
        ),
      );
    }
    retries = 0;
    sources['tracks'].removeWhere((element) => element['kind'] != 'captions');
    return Source(
      qualities: {
        'default': sources['sources'][0]['file'],
      },
      subtitles: {
        for (Map i in sources['tracks']) i['label']: i['file'],
      },
    );
  } catch (_) {
    if (retries == 0) {
      retries++;
      return await zoroInfo(id);
    } else {
      return const Source(qualities: {}, subtitles: {});
    }
  }
}
