import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:tokuwari/models/info_models.dart';

const String baseUrl = 'https://marin.moe/anime';

Provider marinList(final AniData data) async {
  try {
    final List<MediaProv> episodes = [];
    final Map syncResponse =
        (await Dio().get('https://api.malsync.moe/mal/anime/${data.malid}'))
            .data;
    final String id = syncResponse['Sites']['Marin'].keys.first;
    // I have a better way oh?
    final Map info = await request(id, 1);
    if (info['props']['episode_list']['meta']['last_page'] > 1) {
      final List<Future<Map>> requests = [];
      for (int i = 2;
          i <= info['props']['episode_list']['meta']['last_page'];
          i++) {
        requests.add(request(id, i));
        for (Map i in await Future.wait(requests)) {
          info['props']['episode_list']['data'].addAll(
            i['props']['episode_list']['data'],
          );
        }
      }
    }
    for (final Map i in info['props']['episode_list']['data']) {
      episodes.add(
        MediaProv(
          provider: 'marin',
          provId: '$id/${i['sort']}',
          title: (i['title'] == 'No Title') ? "" : i['title'],
          number: i['sort'].toString(),
          call: () => marinInfo('$id/${i['sort']}'),
        ),
      );
    }
    return episodes;
  } catch (_) {
    return [];
  }
}

Anime marinInfo(final String id) async {
  final List<String> headers = await getToken();
  final Options options = Options(
    headers: <String, String>{
      'Origin': 'https://marin.moe/',
      'Referer': 'https://marin.moe/anime/$id',
      'Cookie':
          '__ddg1=;__ddg2_=; XSRF-TOKEN=${headers[0]}; marin_session=${headers[1]}',
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36',
      'x-inertia': 'true',
      'x-inertia-version': '884345c4d568d16e3bb2fb3ae350cca9',
      'x-requested-with': 'XMLHttpRequest',
      'x-xsrf-token': headers[0].replaceAll('%3D', '='),
    },
  );
  final Map info = (await Dio().post(
    '$baseUrl/$id',
    options: options,
  ))
      .data;
  return Source(
    qualities: {
      for (Map i in info['props']['video']['data']['mirror'])
        i['code']['height'].toString(): i['code']['file'],
    },
    subtitles: {},
    headers: options.headers as Map<String, String>,
  );
}

Future<Map> request(final String id, final int index) async {
  final List<String> headers = await getToken();
  final Map info = (await Dio().post(
    '$baseUrl/$id',
    // WOOOOOOOOOoooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
    data: jsonEncode({
      'filter': {
        'episodes': true,
        'specials': true,
      },
      'eps_page': index, //why :()
    }),
    options: Options(
      headers: {
        'Origin': 'https://marin.moe/',
        'Referer': 'https://marin.moe/anime/$id',
        'Cookie':
            '__ddg1=;__ddg2_=; XSRF-TOKEN=${headers[0]}; marin_session=${headers[1]}',
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36',
        'x-inertia': true,
        'x-inertia-version': '884345c4d568d16e3bb2fb3ae350cca9',
        'x-requested-with': 'XMLHttpRequest',
        'x-xsrf-token': headers[0].replaceAll('%3D', '='),
      },
    ),
  ))
      .data; // so lonely down here. I'll await for the day when I can finally meet my beloved brackets again;
  return info;
}

Future<List<String>> getToken() async {
  final String headers = (await Dio().get(
    'https://marin.moe/anime',
    options: Options(
      headers: {
        'Referer': 'https://marin.moe/anime',
        'Cookie': '__ddg1_=;__ddg2_=;',
      },
    ),
  ))
      .headers
      .toString();

  return [
    headers.split('XSRF-TOKEN=')[1].split(';')[0],
    headers.split('marin_session=')[1].split(';')[0]
  ];
}
