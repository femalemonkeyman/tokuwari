import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:tokuwari_models/info_models.dart';

Provider paheList(final AniData data) async {
  try {
    final Map response = (await Dio().get('$anisync/${data.malid}')).data;
    final String syncId = parse(
      (await Dio().get('https://animepahe.com/a/${response['Sites']?['animepahe'].keys.first}')).data,
    ).head!.getElementsByTagName('script').first.text.split('let id = "')[1].split('";')[0];
    final String link = 'https://animepahe.ru/api?m=release&id=$syncId&sort=episode_asc';
    final Map anime = (await Dio().get(link)).data;
    if (anime['last_page'] > 1) {
      for (Response i in await Future.wait(
        [
          for (int i = 2; i <= anime['last_page']; i++) Dio().get('$link&page=$i'),
        ],
      )) {
        anime['data'].addAll(i.data['data']);
      }
    }
    return List.generate(
      anime['data'].length,
      (index) => MediaProv(
        provider: 'animePahe',
        provId: '$syncId/${anime['data'][index]['session']}',
        title: anime['data'][index]['title'],
        number: anime['data'][index]['episode'].toString(),
        call: () => paheInfo('$syncId/${anime['data'][index]['session']}'),
      ),
    );
  } catch (e) {
    return [];
  }
}

Anime paheInfo(final String id) async {
  final List<Element> data = parse(
    (await Dio().get(
      'https://animepahe.ru/play/$id',
      options: Options(
        headers: {
          'referer': 'https://animepahe.ru',
        },
      ),
    ))
        .data,
  )
      .getElementsByTagName('button')
      .where(
        (element) =>
            element.attributes.containsKey('data-src') && (element.attributes['data-src']?.contains('kwik') ?? false),
      )
      .toList();
  return Source(
    qualities: Map.fromIterables(
      [for (Element i in data) '${i.attributes['data-fansub']}-${i.attributes['data-resolution']}'].reversed,
      [
        for (Response i in await Future.wait(
          [
            for (Element i in data)
              Dio().get(
                i.attributes['data-src']!,
                options: Options(
                  headers: {
                    'referer': 'https://animepahe.ru',
                  },
                ),
              )
          ],
        ))
          JsUnpack(
            parse(i.data).getElementsByTagName('script').where((element) => element.text.contains('eval')).first.text,
          ).unpack().split('source=\'')[1].split('\'')[0],
      ].reversed,
    ), //qualities,
    subtitles: {},
    headers: {'referer': 'https://kwik.cx'},
  );
}

class JsUnpack {
  final String source;
  const JsUnpack(this.source);
  static const alphabet = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

  ///Unpacks P.A.C.K.E.R. packed js code
  String unpack() {
    final lst = _filterargs();
    final String payload = lst[0].replaceAll("\\\\", "\\").replaceAll("\\'", "'");
    final List<String> symtab = lst[1];
    String source = payload;
    final reg = RegExp(
      r"\b\w+\b",
    ).allMatches(payload);
    int correct = 0;
    for (RegExpMatch element in reg) {
      final word = payload.substring(element.start, element.end);
      String lookUp = "";
      final v = toBase10(word);
      if (v < symtab.length) {
        try {
          lookUp = symtab[v];
        } catch (_) {}
        if (lookUp.isEmpty) lookUp = word;
      } else {
        lookUp = word;
      }
      source = source.replaceRange(element.start + correct, element.start + word.length + correct, lookUp);
      correct += lookUp.length - (element.end - element.start);
    }
    return _replaceStrings(source);
  }

  String _replaceStrings(String source) {
    var re = RegExp(r'var *(_\w+)=\["(.*?)"];', dotAll: true).firstMatch(source);
    if (re == null) {
      return source;
    }
    final strings = re.group(1)!;
    return source.substring(strings.length);
  }

  List<dynamic> _filterargs() {
    final all = RegExp(r"}\s*\('(.*)',\s*(.*?),\s*(\d+),\s*'(.*?)'\.split\('\|'\)").firstMatch(source);
    if (all == null) {
      throw 'Corrupted p.a.c.k.e.r. data.';
    }
    return [all.group(1), all.group(4)!.split("|"), int.tryParse(all.group(2)!) ?? 36, int.parse(all.group(3)!)];
  }

  int toBase10(String string) {
    return string.split('').fold(0, (int out, char) {
      int charIndex = alphabet.indexOf(char);
      return out * alphabet.length + charIndex;
    });
  }
}
