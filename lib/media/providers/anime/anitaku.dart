import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart';
import 'package:html/parser.dart';
import 'package:tokuwari_models/info_models.dart';

const String gogo = 'https://anitaku.to/';

Provider gogoList(final AniData data) async {
  try {
    final msync = await Dio()
        .get(
          '$anisync/${data.malid}',
          options: Options(
            responseType: ResponseType.plain,
          ),
        )
        .then(
          (value) => jsonDecode(value.data)['Sites']['Gogoanime'].keys.first,
        );
    final gogoPage = await Dio().get(gogo + 'category/' + msync);
    print(gogoPage);
    return [];
  } catch (e) {
    return [];
  }
}

Anime gogoInfo() async {
  final iv = IV.fromUtf8("3134003223491201");
  final episodeResponse = await Dio().get('$gogo/mahoutsukai-no-yome-season-2-episode-7');
  final episode = parse(episodeResponse.data).body?.getElementsByClassName('active')[0].attributes['data-video'];
  final videoResponse = await Dio().get(episode!);
  final encryptedParams = Encrypted.fromBase64(videoResponse.data.split('data-value="')[1].split('"><')[0]);
  final params = String.fromCharCodes(
      AES(Key.fromUtf8('37911490979715163134003223491201'), mode: AESMode.cbc).decrypt(encryptedParams, iv: iv));
  final encrypt = params.split('&')[0];
  final updatedParams = params.replaceAll(
    '$encrypt&',
    '${AES(Key.fromUtf8('37911490979715163134003223491201'), mode: AESMode.cbc).encrypt(
          Uint8List.fromList(encrypt.codeUnits),
          iv: iv,
        ).base64}&',
  );
  final response = await Dio()
      .get(
        'https://playtaku.online/encrypt-ajax.php?id=$updatedParams&alias=$encrypt',
        options: Options(
          headers: {'referer': episode, 'host': 'playtaku.online', 'x-requested-with': 'XMLHttpRequest'},
        ),
      )
      .then((value) => jsonDecode(value.data)['data']);
  final decryptedSources = AES(Key.fromUtf8('54674138327930866480207815084989'), mode: AESMode.cbc)
      .decrypt(Encrypted.fromBase64(response), iv: iv);
  final sources = jsonDecode(String.fromCharCodes(decryptedSources));

  return Source(qualities: sources['source'][0]['file'], subtitles: {});
}
