import 'package:anicross/block.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql/client.dart';
import '../search_button.dart';
import '../grid.dart';
import 'anime_videos.dart';
import 'extra/anilist.dart';

final client = GraphQLClient(
  cache: GraphQLCache(),
  link: HttpLink("https://graphql.anilist.co/"),
);

final genresList = [
  "Action",
  "Adventure",
  "Comedy",
  "Drama",
  "Ecchi",
  "Fantasy",
  "Hentai",
  "Horror",
  "Mahou Shoujo",
  "Mecha",
  "Music",
  "Mystery",
  "Psychological",
  "Romance",
  "Sci-Fi",
  "Slice of Life",
  "Sports",
  "Supernatural",
  "Thriller"
];

aniInfo(id) async {
  String link = "https://api.consumet.org/meta/anilist/info/$id?provider=zoro";
  var json = await Dio().get(link);
  return json.data;
}

episodeInfo(name) async {
  String link =
      "https://api.consumet.org/meta/anilist/watch/$name?provider=zoro";
  var json = await Dio().get(link);
  return json.data;
}

class AniPage extends StatefulWidget {
  const AniPage({Key? key}) : super(key: key);

  @override
  State createState() => AniPageState();
}

class AniPageState extends State<AniPage> with AutomaticKeepAliveClientMixin {
  final TextEditingController textController = TextEditingController();
  late Future queryVar = queryData();
  String? search;
  List<String> selectedGenres = [];
  Map data = {};
  int page = 1;

  @override
  bool get wantKeepAlive => true;

  Future queryData() async {
    QueryResult query = await client.query(
      QueryOptions(
        fetchPolicy: FetchPolicy.networkOnly,
        document: gql(base),
        variables: {
          "page": page,
          'search': search,
          "genre": (selectedGenres.isNotEmpty) ? selectedGenres : null,
        },
      ),
    );
    return query.data;
  }

  Future updateData() async {
    final query = await queryData();
    data['Page']['pageInfo'].addAll(query['Page']['pageInfo']);
    data['Page']['media'].addAll(query['Page']['media']);
  }

  Future searchData() async {
    page = 1;
    if (textController.text.isNotEmpty) {
      selectedGenres = [];
      search = textController.text;
    } else {
      search = null;
    }
    setState(() {
      queryVar = queryData();
    });
  }

  Future updateGenre() async {
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => SimpleDialog(
            children: [
              SizedBox(
                width: 200,
                child: Wrap(
                  spacing: 500,
                  children: List.generate(
                    genresList.length,
                    (index) {
                      return CheckboxListTile(
                        value: selectedGenres.contains(
                          genresList[index],
                        ),
                        title: Text(
                          genresList[index],
                        ),
                        onChanged: (value) async {
                          if (value!) {
                            selectedGenres.add(genresList[index]);
                          } else {
                            selectedGenres.remove(genresList[index]);
                          }
                          setState(
                            () {},
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then(
      (value) => setState(
        () {
          queryVar = queryData();
        },
      ),
    );
  }

  @override
  Widget build(context) {
    super.build(context);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 600) {
          if (data['Page']['pageInfo']['hasNextPage'] &&
              data['Page']['pageInfo']['currentPage'] + 1 != page) {
            page = data['Page']['pageInfo']['currentPage'] + 1;
            updateData().whenComplete(() => setState(() {}));
          }
        }
        return true;
      },
      child: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: SearchButton(
              text: "Anilist",
              controller: textController,
              search: () async {
                await searchData();
                setState(() {});
              },
            ),
          ),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: () => updateGenre(),
                child: const Text(
                  "Filter by genre",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const Divider(),
          FutureBuilder(
            future: queryVar,
            builder: (context, AsyncSnapshot snap) {
              if (snap.hasData &&
                  snap.connectionState == ConnectionState.done) {
                data = snap.data;
                return Grid(
                  data: List.generate(
                    data['Page']['media'].length,
                    (index) {
                      return Block(
                        mediaList: AniEpisodes(
                          id: data['Page']['media'][index]['id'].toString(),
                        ),
                        title:
                            "${data['Page']['media'][index]['title']['romaji']}",
                        image: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: CachedNetworkImage(
                            fit: BoxFit.contain,
                            imageUrl: data['Page']['media'][index]['coverImage']
                                ['extraLarge'],
                          ),
                        ),
                        count:
                            (data['Page']['media'][index]['episodes'] ?? "n/a")
                                .toString(),
                        score: data['Page']['media'][index]['averageScore'],
                        description:
                            data['Page']['media'][index]['description'] ?? "",
                      );
                    },
                  ), //data!['Page']['media'],
                );
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          )
        ],
      ),
    );
  }
}

class AniEpisodes extends StatelessWidget {
  final id;
  const AniEpisodes({
    this.id,
    super.key,
  });

  @override
  Widget build(context) {
    return FutureBuilder<dynamic>(
      future: aniInfo(id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: snapshot.data['episodes'].length,
            itemBuilder: ((context, index) {
              return ListTile(
                title: Text(
                  "Episode: ${(snapshot.data["episodes"][index]["title"]) ?? snapshot.data['episodes'][index]['number']}",
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return Scaffold(
                        body: RawKeyboardListener(
                          autofocus: true,
                          focusNode: FocusNode(),
                          onKey: (value) {
                            if (value.isKeyPressed(LogicalKeyboardKey.escape)) {
                              Navigator.pop(context);
                            }
                          },
                          child: FutureBuilder<dynamic>(
                            future: episodeInfo(
                                snapshot.data['episodes'][index]['id']),
                            builder: (context, info) {
                              if (info.hasData) {
                                return AniViewer(
                                  sources: info.data['sources'] ?? [],
                                  subtitles: info.data['subtitles'] ?? [],
                                );
                              }
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
