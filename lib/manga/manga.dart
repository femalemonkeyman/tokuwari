import '../providers/info_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../widgets/grid.dart';
import '../widgets/search_button.dart';
import 'manga_reader.dart';

const mangadex = "https://api.mangadex.org/";

dexReader(id) async {
  List chapters = [];
  var json = await Dio().get(
    "${mangadex}manga/$id/aggregate?translatedLanguage[]=en",
  );
  for (var i in json.data['volumes'].values) {
    if (i['chapters'] is List) {
      i['chapters'] = {
        i['chapters'][0]['chapter']: i['chapters'][0],
      };
    }
    for (var j in i['chapters'].values) {
      chapters.add(j);
    }
  }
  return chapters;
}

class MangaPage extends StatefulWidget {
  const MangaPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MangaPageState();
}

class MangaPageState extends State<MangaPage> {
  final TextEditingController textController = TextEditingController();
  late final tags = Dio().get("$mangadex/tag");
  List<AniData> mangaData = [];
  List data = [];
  int offset = 0;
  String search = "";

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await getData();
      setState(() {});
    });
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future updateData() async {
    await getData();
    setState(() {});
  }

  Future searchData() async {
    offset = 0;
    mangaData = [];
    if (textController.text.isNotEmpty) {
      search = textController.text;
    } else {
      search = "";
    }
    await getData();
    setState(
      () {},
    );
  }

  Future<void> getData() async {
    final json = await Dio().get(
      "${mangadex}manga/?includes[]=cover_art&limit=100&order[followedCount]=desc&hasAvailableChapters=1&availableTranslatedLanguage[]=en&title=$search&offset=$offset",
    );
    final data = json.data['data'];
    mangaData.addAll(
      List.generate(
        json.data['data'].length,
        (index) {
          return AniData(
            type: "manga",
            mediaId: data[index]['id'],
            title: data[index]['attributes']['title'].values.first,
            image:
                "https://uploads.mangadex.org/covers/${data[index]['id']}/${data[index]['relationships'][data[index]['relationships'].indexWhere((i) => i['type'] == "cover_art")]['attributes']['fileName']}.512.jpg",
            description: (data[index]['attributes']['description'].length == 0)
                ? "No description provided."
                : data[index]['attributes']['description']['en'],
            count: ((data[index]['attributes']['lastChapter'])
                    .toString()
                    .isNotEmpty)
                ? data[index]['attributes']['lastChapter']
                : data[index]['attributes']['status'],
            tags: [],
          );
        },
      ),
    );

    //return json.data['data'];
  }

  @override
  Widget build(context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 600 && offset <= data.length) {
          offset += 101;
          updateData();
        }
        return true;
      },
      child: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: SearchButton(
              text: "Mangadex",
              controller: textController,
              search: () => searchData(),
            ),
          ),
          (mangaData.isNotEmpty)
              ? Grid(
                  data: mangaData,
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
        ],
      ),
    );
  }
}

class MangaChapters extends StatelessWidget {
  final String id;

  const MangaChapters({Key? key, required this.id}) : super(key: key);
  @override
  Widget build(context) {
    return FutureBuilder<dynamic>(
      future: dexReader(id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: snapshot.data?.length,
            itemBuilder: ((
              context,
              index,
            ) {
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return Scaffold(
                        body: MangaReader(
                          current: snapshot.data[index]['id'],
                          chapters: snapshot.data,
                          index: index,
                        ),
                      );
                    },
                  ),
                ),
                child: Container(
                  height: 40,
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.blueGrey)),
                  ),
                  child: Text("Chapter: ${snapshot.data?[index]['chapter']}"),
                ),
              );
            }),
          );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
