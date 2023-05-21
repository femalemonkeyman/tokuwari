import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:anicross/models/info_models.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:string_similarity/string_similarity.dart';

//Zoro
Future<List<MediaProv>> zoroList(id) async {
  const String zoro = "https://zoro.to/";
  try {
    final Map syncResponse = jsonDecode(
      (await Dio().get(
        'https://raw.githubusercontent.com/MALSync/MAL-Sync-Backup/master/data/anilist/anime/$id.json',
      ))
          .data,
    );
    final Response html = await Dio().get(
      '${zoro}ajax/v2/episode/list/${syncResponse['Pages']['Zoro'].keys.first}',
      options: Options(
        responseType: ResponseType.plain,
      ),
    );
    final Document episodeList = parse(jsonDecode(html.data)['html']);
    List<MediaProv> episodes = [];
    for (Element i in episodeList.getElementsByClassName('ssl-item  ep-item')) {
      episodes.add(
        MediaProv(
          provider: 'zoro',
          provId: i.attributes['data-id']!,
          title: i.attributes['title']!,
          number: i.attributes['data-number']!,
          call: () => zoroInfo(i.attributes['data-id']),
        ),
      );
    }
    return episodes;
  } catch (e) {
    print(e);
    return [];
  }
}

Future<Map> zoroInfo(id) async {
  final Options options = Options(responseType: ResponseType.plain);
  final Response servers = await Dio().get(
    'https://zoro.to/ajax/v2/episode/servers?episodeId=$id',
    options: options,
  );
  final Document html = parse(
    jsonDecode(
      servers.data,
    )['html'],
  );
  Element server = html
      .getElementsByClassName("item server-item")
      .firstWhere((element) => element.text.contains('Vid'));
  try {
    final Map link = jsonDecode(
      (await Dio().get(
        'https://zoro.to/ajax/v2/episode/sources?id=${server.attributes['data-id']}',
        options: options,
      ))
          .data,
    );
    Map<String, dynamic> sources = jsonDecode(
      (await Dio().get(
              'https://rapid-cloud.co/ajax/embed-6/getSources?id=${link['link'].split('6/')[1].split('?')[0]}',
              options: options))
          .data,
    );
    final String key = (await Dio().get(
            'https://raw.githubusercontent.com/enimax-anime/key/e6/key.txt'))
        .data;
    if (sources['encrypted']) {
      sources['sources'] =
          jsonDecode(decryptAESCryptoJS(sources['sources'], key));
      sources['sourcesBackup'] =
          jsonDecode(decryptAESCryptoJS(sources['sourcesBackup'], key));
    }
    sources['sources'] = List.generate(sources['sources'].length, (index) {
      return {'url': sources['sources'][index]['file']};
    });
    return sources;
  } catch (e) {
    return {};
  }
}
// End Zoro

//Begin Hanime
Future<List?> haniList(String name) async {
  Response json = await Dio().post(
    "https://search.htv-services.com/",
    data: jsonEncode(
      {
        "search_text": (name.split(" ").length > 3)
            ? name.split(" ").getRange(0, 3).join(" ")
            : name.replaceAll("☆", " "),
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
    for (Map i in results) {
      Response v = await Dio().get(
        "https://hanime.tv/api/v8/video?id=${i['id']}",
      );
      if (i['name'].toString().similarityTo(name) > 0.2) {
        videos.add(v.data);
      }
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
//End hanime

// Response json = await Dio().get(
//   "https://api.consumet.org/meta/anilist/info/$id?provider=zoro",
// );
// return (json.data['episodes'].isEmpty)
//     ? null
//     : List.generate(
//         json.data['episodes'].length,
//         (index) {
//           return {
//             "id": json.data['episodes'][index]['id'],
//             "title": json.data['episodes'][index]['title'],
//             "number": "Episode: ${json.data['episodes'][index]['number']}",
//             "description": json.data['episodes'][index]['description']
//           };
//         },
//       );

// try {
//   Response json = await Dio().get(
//     "https://api.consumet.org/meta/anilist/watch/$id?provider=zoro",
//   );
//   return json.data;
// } catch (e) {
//   return null;
// }

String decryptAESCryptoJS(final String encrypted, final String passphrase) {
  try {
    Uint8List encryptedBytesWithSalt = base64.decode(encrypted);
    Uint8List encryptedBytes =
        encryptedBytesWithSalt.sublist(16, encryptedBytesWithSalt.length);
    final salt = encryptedBytesWithSalt.sublist(8, 16);
    final List<Uint8List> keyndIV = deriveKeyAndIV(passphrase, salt);
    final key = encrypt.Key(keyndIV[0]);
    final iv = encrypt.IV(keyndIV[1]);
    final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: "PKCS7"));
    final decrypted =
        encrypter.decrypt64(base64.encode(encryptedBytes), iv: iv);
    return decrypted;
  } catch (error) {
    rethrow;
  }
}

List<Uint8List> deriveKeyAndIV(final String passphrase, final Uint8List salt) {
  var password = createUint8ListFromString(passphrase);
  Uint8List concatenatedHashes = Uint8List(0);
  Uint8List currentHash = Uint8List(0);
  Uint8List preHash = Uint8List(0);

  while (concatenatedHashes.length < 48) {
    if (currentHash.isNotEmpty) {
      preHash = Uint8List.fromList(currentHash + password + salt);
    } else {
      preHash = Uint8List.fromList(password + salt);
    }
    currentHash = Uint8List.fromList(md5.convert(preHash).bytes);
    concatenatedHashes = Uint8List.fromList(concatenatedHashes + currentHash);
  }
  return [
    concatenatedHashes.sublist(0, 32),
    concatenatedHashes.sublist(32, 48),
  ];
}

Uint8List createUint8ListFromString(final String s) {
  Uint8List ret = Uint8List(s.length);
  for (var i = 0; i < s.length; i++) {
    ret[i] = s.codeUnitAt(i);
  }
  return ret;
}

Uint8List genRandomWithNonZero(final int seedLength) {
  final Random random = Random.secure();
  const int randomMax = 245;
  final Uint8List uint8list = Uint8List(seedLength);
  for (int i = 0; i < seedLength; i++) {
    uint8list[i] = random.nextInt(randomMax) + 1;
  }
  return uint8list;
}
