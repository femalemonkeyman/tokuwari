import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_io/io.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

const anilist = "https://graphql.anilist.co/";
const mangadex = "https://api.mangadex.org/";

dexSearch(title) async {
  List data = [];
  var json =
      await Dio().get("${mangadex}manga/?includes[]=cover_art&title=$title");
  for (var i in json.data['data']) {
    data.add(i);
  }
  return data;
}

dexPages(chapterId, reversed) async {
  List pages = [];
  var json =
      await Dio().get("https://api.mangadex.org/at-home/server/$chapterId");
  for (var page in json.data['chapter']['data']) {
    pages.add(
        "https://uploads.mangadex.org/data/${json.data['chapter']['hash']}/$page");
  }
  if (reversed) {
    pages = pages.reversed.toList();
  }
  return pages;
}

dexReader(id) async {
  List chapters = [];
  var json =
      await Dio().get("${mangadex}manga/$id/aggregate?translatedLanguage[]=en");

  //print(json.data['volumes']['2'].forEach((k, v) => print(v)));

  for (var i in json.data['volumes'].values) {
    if (i['chapters'] is List) {
      i['chapters'] = {i['chapters'][0]['chapter']: i['chapters'][0]};
    }
    for (var j in i['chapters'].values) {
      chapters.add(j);
    }
  }

  //print(id);
  //print(chapters);
  return chapters;
}

dexList() async {
  Map data = {};
  var json = await Dio().get(
      "${mangadex}manga/?includes[]=cover_art&limit=100&order[followedCount]=desc&availableTranslatedLanguage[]=en");
  for (var i in json.data['data']) {
    data['title'] = i['title'];
  }
  return await json.data;
}

getFilepath() async {
  String? directory;
  if (Platform.isAndroid) {
    await Permission.manageExternalStorage.request();
  }
  directory = await FilePicker.platform.getDirectoryPath();

  if (directory != null) {
    //print(await Directory(directory).list().length);
    //Hive.box("settings").put("novels", directory);
    return Directory(directory);
  }
}

const base = """
  {
  Page(perPage: 50, page: 1) {
    pageInfo {
      currentPage
      hasNextPage
    },
      media(sort: [TRENDING_DESC], type: ANIME) {
        id
        title {
          romaji
          english
          native
        }
        type
        chapters
        averageScore
        episodes
        description
        coverImage{
          extraLarge
        }
        episodes
        tags {
          name
        }
      }
  }
}
""";

const listSearch = """
query media(\$search: String!)
{
  Page(perPage: 50, page: 1,) {
    pageInfo {
      total
      perPage
      currentPage
      lastPage
      hasNextPage
    }
  	media(search: \$search, type: ANIME) {
  	  title {
  	    romaji
  	    english
  	    native
  	  }
      averageScore
        episodes
        description
        coverImage{
          extraLarge
        }
        episodes
        tags {
          name
        }
  	}
  }
}

""";

int date = DateTime.now()
        .toUtc()
        .subtract(
          Duration(
              hours: DateTime.now().toUtc().hour >= 15
                  ? DateTime.now().toUtc().hour - 15
                  : DateTime.now().toUtc().hour + 9,
              minutes: DateTime.now().toUtc().minute,
              seconds: DateTime.now().toUtc().second),
        )
        .millisecondsSinceEpoch ~/
    1000;

final ValueNotifier<GraphQLClient> client = ValueNotifier(
  GraphQLClient(
    cache: GraphQLCache(),
    link: HttpLink(anilist),
  ),
);
