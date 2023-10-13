//RIP
// import 'dart:convert';
// import 'package:dio/dio.dart';
// import 'package:intl/intl.dart';
// import 'package:tokuwari_models/info_models.dart';

// const String baseUrl = 'https://marin.moe/anime';
// final List<String> headers = [];

// Provider marinList(final AniData data) async {
//   try {
//     final Map syncResponse =
//         (await Dio().get('https://api.malsync.moe/mal/anime/${data.malid}'))
//             .data;
//     final String id = syncResponse['Sites']['Marin'].keys.first;
//     final Map info = await request(id, 1);
//     if (info['props']['episode_list']['meta']['last_page'] > 1) {
//       final List<Future<Map>> requests = [
//         for (int i = 2;
//             i <= info['props']['episode_list']['meta']['last_page'];
//             i++)
//           request(id, i),
//       ];
//       for (Map i in await Future.wait(requests)) {
//         info['props']['episode_list']['data'].addAll(
//           i['props']['episode_list']['data'],
//         );
//       }
//     }
//     return [
//       for (final Map i in info['props']['episode_list']['data'])
//         MediaProv(
//           provider: 'marin',
//           provId: '$id/${i['sort']}',
//           title: (i['title'] == 'No Title') ? "" : i['title'],
//           number: i['sort'].toString(),
//           call: () => marinInfo('$id/${i['sort']}'),
//         ),
//     ];
//   } catch (_) {
//     return [];
//   }
// }

// Anime marinInfo(final String id) async {
//   await getToken();
//   final Options options = Options(
//     headers: <String, String>{
//       'Origin': 'https://marin.moe/',
//       'Referer': 'https://marin.moe/anime/$id',
//       'Cookie':
//           '__ddg1=;__ddg2_=; XSRF-TOKEN=${headers[0]}; marin_session=${headers[1]}',
//       'User-Agent':
//           'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36',
//       'x-inertia': 'true',
//       'x-inertia-version': '884345c4d568d16e3bb2fb3ae350cca9',
//       'x-requested-with': 'XMLHttpRequest',
//       'x-xsrf-token': headers[0].replaceAll('%3D', '='),
//     },
//   );
//   final Map info = (await Dio().post(
//     '$baseUrl/$id',
//     options: options,
//   ))
//       .data;
//   return Source(
//     qualities: {
//       for (Map i in info['props']['video']['data']['mirror'])
//         i['code']['height'].toString(): i['code']['file'],
//     },
//     subtitles: {},
//     headers: options.headers as Map<String, String>,
//   );
// }

// Future<Map> request(final String id, final int index) async {
//   await getToken();
//   final Map info = (await Dio().post(
//     '$baseUrl/$id',
//     data: jsonEncode({
//       'filter': {
//         'episodes': true,
//         'specials': true,
//       },
//       'eps_page': index,
//     }),
//     options: Options(
//       headers: {
//         'Origin': 'https://marin.moe/',
//         'Referer': 'https://marin.moe/anime/$id',
//         'Cookie':
//             '__ddg1=;__ddg2_=; XSRF-TOKEN=${headers[0]}; marin_session=${headers[1]}',
//         'User-Agent':
//             'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
//         'x-inertia': true,
//         'x-inertia-version': '884345c4d568d16e3bb2fb3ae350cca9',
//         'x-requested-with': 'XMLHttpRequest',
//         'x-xsrf-token': headers[0].replaceAll('%3D', '='),
//       },
//     ),
//   ))
//       .data; // so lonely down here. I'll await for the day when I can finally meet my beloved brackets again;
//   return info;
// }

// Future<void> getToken() async {
//   if (headers.isEmpty) {
//     final String head = (await Dio().get(
//       'https://marin.moe/anime',
//       options: Options(
//         headers: {
//           'Referer': 'https://marin.moe/anime',
//           'Cookie': '__ddg1_=;__ddg2_=;',
//         },
//       ),
//     ))
//         .headers
//         .toString();
//     headers.addAll(
//       [
//         head.split('XSRF-TOKEN=')[1].split(';')[0],
//         head.split('marin_session=')[1].split(';')[0],
//         head.split('expires=')[1].split(';')[0]
//       ],
//     );
//   } else if (DateTime.now().toUtc().compareTo(
//             DateFormat('EEE, d MMM yyyy hh:mm:ss vvv').parse(headers[2]),
//           ) >
//       -1) {
//     headers.clear();
//     getToken();
//   }
// }
