import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../block.dart';
import '../grid.dart';
import '../search_button.dart';

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
  for (var i in json.data['volumes'].values) {
    if (i['chapters'] is List) {
      i['chapters'] = {i['chapters'][0]['chapter']: i['chapters'][0]};
    }
    for (var j in i['chapters'].values) {
      chapters.add(j);
    }
  }
  print(chapters);
  return chapters;
}

dexList() async {
  var json = await Dio().get(
      "${mangadex}manga/?includes[]=cover_art&limit=100&order[followedCount]=desc&availableTranslatedLanguage[]=en");
  return json.data;
}

class MangaPage extends StatefulWidget {
  const MangaPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MangaPageState();
}

class MangaPageState extends State<MangaPage> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController textController = TextEditingController();
  late final getVar = getData();
  List data = [];

  Future<List> getData() async {
    data = (await dexList())['data'];
    return data;
  }

  @override
  Widget build(context) {
    return ListView(
      controller: scrollController,
      shrinkWrap: true,
      children: [
        Center(
          child: SearchButton(
            text: "Mangadex",
            controller: textController,
            search: () {},
          ),
        ),
        (data.isEmpty)
            ? FutureBuilder<List>(
                future: getVar,
                builder: (context, snapshot) {
                  print(snapshot.error);
                  if (snapshot.hasData) {
                    return Grid(
                      data: List.generate(
                        data.length,
                        (index) {
                          print(data[index]['id']);
                          return Block(
                            title:
                                data[index]['attributes']['title'].values.first,
                            image: CachedNetworkImage(
                              imageUrl:
                                  "https://uploads.mangadex.org/covers/${data[index]['id']}/${data[index]['relationships'][data[index]['relationships'].indexWhere((i) => i['type'] == "cover_art")]['attributes']['fileName']}.512.jpg",
                            ),
                            description: (data[index]['attributes']
                                            ['description']
                                        .length ==
                                    0)
                                ? "No description provided."
                                : data[index]['attributes']['description']
                                    ['en'],
                            count: int.tryParse(
                              data[index]['attributes']['lastChapter'] ?? "",
                            ),
                            mediaList: MangaChapters(id: data[index]['id']),
                          );
                        },
                      ),
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              )
            : Grid(
                data: List.generate(
                  data.length,
                  (index) {
                    return Block(
                      title: data[index]['attributes']['title'].values.first,
                      image: CachedNetworkImage(
                          imageUrl:
                              "https://uploads.mangadex.org/covers/${data[index]['id']}/${data[index]['relationships'][data[index]['relationships'].indexWhere((i) => i['type'] == "cover_art")]['attributes']['fileName']}.512.jpg"),
                      description:
                          (data[index]['attributes']['description'].length == 0)
                              ? "No description provided."
                              : data[index]['attributes']['description']['en'],
                      count: int.tryParse(
                        data[index]['attributes']['lastChapter'] ?? "",
                      ),
                      mediaList: MangaChapters(id: data[index]['id']),
                    );
                  },
                ),
              ),
      ],
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
        if (snapshot.hasError) {
          print(snapshot.error);
        }
        if (snapshot.hasData) {
          //print(snapshot.data);
          return ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: snapshot.data?.length,
            itemBuilder: ((
              context,
              index,
            ) {
              //print(snapshot.data.length);
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

class MangaReader extends StatelessWidget {
  final String current;
  final List chapters;
  final int index;
  final bool reverse;
  final PageController controller = PageController();

  MangaReader(
      {Key? key,
      required this.current,
      required this.index,
      required this.chapters,
      this.reverse = false})
      : super(key: key);

  @override
  Widget build(context) {
    return FutureBuilder<dynamic>(
      future: dexPages(current, reverse),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (reverse) {}
          return Column(
            children: [
              const BackButton(),
              Expanded(
                  child: Stack(
                children: [
                  RawKeyboardListener(
                    onKey: (event) {
                      //print(event.isKeyPressed(LogicalKeyboardKey.arrowLeft));
                      if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
                        controller.jumpToPage(controller.page!.toInt() + 1);
                      } else if (event
                          .isKeyPressed(LogicalKeyboardKey.arrowRight)) {
                        controller.jumpToPage(controller.page!.toInt() - 1);
                      }
                    },
                    focusNode: FocusNode(),
                    child: PageView.builder(
                      controller: controller,
                      allowImplicitScrolling: true,
                      reverse: true,
                      //preloadPagesCount: 3,
                      //scrollDirection: Axis.horizontal,
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) {
                        return InteractiveViewer(
                          child: Stack(
                            children: [
                              Center(
                                child: CachedNetworkImage(
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  imageUrl: snapshot.data?[index],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Center(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              controller
                                  .jumpToPage(controller.page!.toInt() + 1);
                            },
                          ),
                        ),
                        const Spacer(),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              controller
                                  .jumpToPage(controller.page!.toInt() - 1);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )),
            ],
          );
        }
        return Column(
          children: const [
            Align(
              alignment: Alignment.topLeft,
              child: BackButton(),
            ),
            Spacer(),
            Center(
              child: CircularProgressIndicator(),
            ),
            Spacer()
          ],
        );
      },
    );
  }
}
