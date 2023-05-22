import '../models/info_models.dart';
import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import '../widgets/search_button.dart';
import '../widgets/grid.dart';

const base = """
query (\$page: Int!, \$type: MediaType, \$tag: String, \$search: String, \$genre: [String])
  {
  Page(perPage: 50, page: \$page) {
    pageInfo {
      hasNextPage
      lastPage
      total
      currentPage
    },
    media(sort: [TRENDING_DESC], type: \$type, search: \$search, genre_in: \$genre, tag: \$tag) {
      id
        title {
          romaji
          english
          native
        }
        idMal
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

const genresList = [
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
  final String? tag;
  final String type;
  const AniPage({Key? key, required this.type, this.tag}) : super(key: key);

  @override
  State createState() => AniPageState();
}

class AniPageState extends State<AniPage> {
  final TextEditingController textController = TextEditingController();
  String? search;
  bool loading = false;
  List<String> selectedGenres = [];
  late final String? tag = widget.tag;
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

  Future queryData() async {
    QueryResult query = await client.query(
      QueryOptions(
        fetchPolicy: FetchPolicy.networkOnly,
        document: gql(base),
        variables: {
          "page": (pageInfo.isEmpty) ? 1 : pageInfo['currentPage'] + 1,
          'type': widget.type.toUpperCase(),
          'search': search,
          "genre": (selectedGenres.isNotEmpty) ? selectedGenres : null,
          "tag": tag,
        },
      ),
    );
    pageInfo = query.data!['Page']['pageInfo'];
    animeData.addAll(
      List.generate(
        query.data!['Page']['media'].length,
        (index) {
          return AniData(
            type: widget.type,
            mediaId: query.data!['Page']['media'][index]['id'].toString(),
            description:
                (query.data!['Page']['media'][index]['description'] ?? "")
                    .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' '),
            title: "${query.data!['Page']['media'][index]['title']['romaji']}",
            image: query.data!['Page']['media'][index]['coverImage']
                ['extraLarge'],
            count: (query.data!['Page']['media'][index]['episodes'] ?? "n/a")
                .toString(),
            score:
                (query.data!['Page']['media'][index]['averageScore'] ?? "n/a")
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
    loading = false;
  }

  Future<void> updateData() async {
    await queryData();
  }

  Future searchData() async {
    pageInfo['currentPage'] = 0;
    animeData = [];
    if (textController.text.isNotEmpty) {
      selectedGenres = [];
      search = textController.text;
    } else {
      selectedGenres = [];
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
          builder: (context, setState) => AlertDialog(
            content: SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: List.generate(
                    genresList.length,
                    (index) {
                      return FilterChip(
                        labelPadding: const EdgeInsets.all(15),
                        padding: const EdgeInsets.all(2),
                        selected: selectedGenres.contains(
                          genresList[index],
                        ),
                        label: Text(
                          genresList[index],
                        ),
                        onSelected: (value) => setState(
                          () {
                            if (value) {
                              selectedGenres.add(genresList[index]);
                            } else {
                              selectedGenres.remove(genresList[index]);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Okay"),
              ),
            ],
          ),
        );
      },
    ).then((value) async {
      pageInfo = {};
      animeData = [];
      await queryData();
      setState(
        () {},
      );
    });
  }

  @override
  Widget build(context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels ==
                notification.metrics.maxScrollExtent &&
            pageInfo['lastPage'] != pageInfo['currentPage'] &&
            !loading) {
          loading = true;
          Future.microtask(
            () async {
              await updateData();
              setState(() {});
            },
          );
        }
        return true;
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: SearchButton(
                text: "Anilist",
                controller: textController,
                search: () async {
                  await searchData();
                  setState(() {});
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Wrap(
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
          ),
          (animeData.isNotEmpty)
              ? Grid(
                  data: animeData,
                )
              : const SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
        ],
      ),
    );
  }
}
