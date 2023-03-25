import '../providers/info_models.dart';
import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import '../widgets/search_button.dart';
import '../widgets/grid.dart';

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
                        onSelected: (value) async {
                          if (value) {
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
    return CustomScrollView(
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
                paginate: () async {
                  if (page != pageInfo['currentPage'] + 1) {
                    page = pageInfo['currentPage'] + 1;
                    await updateData();
                    setState(() {});
                  }
                },
              )
            : const SliverToBoxAdapter(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
      ],
    );
  }
}
