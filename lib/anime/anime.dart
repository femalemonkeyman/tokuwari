import '../providers/info_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql/client.dart';
import '../widgets/search_button.dart';
import '../widgets/grid.dart';
import 'anime_videos.dart';

const base = """
query (\$page: Int!, \$search: String, \$genre: [String])
  {
  Page(perPage: 50, page: \$page) {
    pageInfo {
      hasNextPage
      lastPage
      total
      currentPage
    },
    media(sort: [TRENDING_DESC], type: ANIME, search: \$search, genre_in: \$genre) {
      id
        title {
          romaji
          english
          native
        }
        status
        averageScore
        description(asHtml: false)
        episodes
        coverImage {
          extraLarge
        }
        tags {
          name
       }
    }
  }
}
""";

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

class AniPage extends StatefulWidget {
  const AniPage({Key? key}) : super(key: key);

  @override
  State createState() => AniPageState();
}

class AniPageState extends State<AniPage> with AutomaticKeepAliveClientMixin {
  final TextEditingController textController = TextEditingController();
  String? search;
  List<String> selectedGenres = [];
  int page = 1;
  Map pageInfo = {};
  List<AniData> animeData = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await queryData();
      setState(() {});
    });
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

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
    pageInfo = query.data!['Page']['pageInfo'];
    animeData.addAll(
      List.generate(
        query.data!['Page']['media'].length,
        (index) {
          return AniData(
            type: "anime",
            mediaId: query.data!['Page']['media'][index]['id'].toString(),
            description:
                (query.data!['Page']['media'][index]['description'] ?? "")
                    .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' '),
            title: "${query.data!['Page']['media'][index]['title']['romaji']}",
            image: query.data!['Page']['media'][index]['coverImage']
                ['extraLarge'],
            count: (query.data!['Page']['media'][index]['episodes'] ?? "n/a")
                .toString(),
            score: (query.data!['Page']['media'][index]['averageScore'])
                .toString(),
            tags: List.generate(
              query.data!['Page']['media'][index]['tags'].length,
              (tagIndex) {
                return query.data!['Page']['media'][index]['tags'][tagIndex]
                    ['name'];
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> updateData() async {
    await queryData();
  }

  Future searchData() async {
    page = 1;
    animeData = [];
    if (textController.text.isNotEmpty) {
      selectedGenres = [];
      search = textController.text;
    } else {
      search = null;
    }
    await queryData();
    setState(() {});
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
    ).then((value) async {
      animeData = [];
      await queryData();
      setState(
        () {},
      );
    });
  }

  @override
  Widget build(context) {
    super.build(context);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 600 &&
            pageInfo['hasNextPage'] &&
            pageInfo['currentPage'] + 1 != page) {
          page = pageInfo['currentPage'] + 1;
          updateData();
          setState(() {});
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
          const Divider(
            height: 3,
          ),
          (animeData.isNotEmpty)
              ? Grid(data: animeData)
              : const Center(
                  child: CircularProgressIndicator(),
                ),
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

  aniInfo(id) async {
    String link =
        "https://api.consumet.org/meta/anilist/info/$id?provider=zoro";
    var json = await Dio().get(link);
    return json.data;
  }

  episodeInfo(name) async {
    String link =
        "https://api.consumet.org/meta/anilist/watch/$name?provider=zoro";
    var json = await Dio().get(link);
    return json.data;
  }

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
                  "Episode: ${index + 1} ${(snapshot.data["episodes"][index]["title"]) ?? snapshot.data['episodes'][index]['number']}",
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
