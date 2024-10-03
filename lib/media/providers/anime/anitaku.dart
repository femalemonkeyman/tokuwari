import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart';
import 'package:html/parser.dart';
import 'package:tokuwari/models/anidata.dart';
import 'package:tokuwari/models/media_prov.dart';
import 'package:tokuwari/models/source.dart';
import 'package:tokuwari/models/types.dart';

const String gogo = 'https://anitaku.pe';

Provider gogoList(final AniData data) async {
  try {
    final msync = await Dio()
        .get(
      '$anisync/${data.malid}',
      options: Options(
        responseType: ResponseType.plain,
      ),
    )
        .then((value) {
      return jsonDecode(value.data)['Sites']['Gogoanime'].keys.first;
    });
    final gogoPage = await Dio().get('$gogo/category/$msync');
    final goid = parse(gogoPage.data).getElementsByClassName('movie_id').first.attributes['value'];
    final episodeList =
        await Dio().get('https://ajax.gogocdn.net/ajax/load-list-episode?ep_start=0&ep_end=9999&id=$goid');
    return [
      for (final src in parse(episodeList.data).getElementsByTagName('a').reversed)
        MediaProv(
          provider: 'gogo',
          provId: '$gogo${src.attributes['href']?.trim()}',
          title: '',
          number: src.getElementsByClassName('name').first.nodes[1].text!.trim(),
          call: () => gogoInfo('$gogo${src.attributes['href']?.trim()}'),
        )
    ];
  } catch (e) {
    print(e);
    return [];
  }
}

Anime gogoInfo(final String id) async {
  try {
    final iv = IV.fromUtf8("3134003223491201");
    final inst = AES(Key.fromUtf8('37911490979715163134003223491201'), mode: AESMode.cbc);
    final episodeResponse = await Dio().get(id);
    final episode = parse(episodeResponse.data).body?.getElementsByClassName('active')[0].attributes['data-video'];
    final videoResponse = await Dio().get(episode!);
    final encryptedParams = Encrypted.fromBase64(videoResponse.data.split('data-value="')[1].split('"><')[0]);
    final params = String.fromCharCodes(inst.decrypt(encryptedParams, iv: iv));
    final encrypt = params.split('&')[0];
    final updatedParams = params.replaceFirst(
      '$encrypt&',
      '${inst.encrypt(
            Uint8List.fromList(encrypt.codeUnits),
            iv: iv,
          ).base64}&',
    );
    final response = await Dio()
        .get(
          'https://s3taku.com/encrypt-ajax.php?id=$updatedParams&alias=$encrypt',
          options: Options(
            headers: {'referer': episode, 'host': 's3taku.com', 'x-requested-with': 'XMLHttpRequest'},
          ),
        )
        .then((value) => jsonDecode(value.data)['data']);
    final decryptedSources = AES(Key.fromUtf8('54674138327930866480207815084989'), mode: AESMode.cbc)
        .decrypt(Encrypted.fromBase64(response), iv: iv);
    final sources = jsonDecode(String.fromCharCodes(decryptedSources));
    return Source(qualities: {'default': sources['source'][0]['file']}, subtitles: {});
  } catch (_, stack) {
    print(stack);
    return const Source(qualities: {}, subtitles: {});
  }
}
