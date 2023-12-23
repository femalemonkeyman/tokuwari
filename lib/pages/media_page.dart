import 'dart:ui';
import 'package:tokuwari_models/info_models.dart';

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
      status
      chapters
      idMal
      genres
      status
      averageScore
      description(asHtml: false)
      episodes
      relations {
        edges {
          id
          node {
            id
          }
        }
      }
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
  "Thriller",
];

class AniPage extends StatefulWidget {
  final String? tag;
  final String type;
  const AniPage({super.key, required this.type, this.tag});

  @override
  State createState() => AniPageState();
}

class AniPageState extends State<AniPage> {
  final TextEditingController textController = TextEditingController();
  final List<String> selectedGenres = [];
  late String? tag = widget.tag;
  final Map pageInfo = {};
  final List<AniData> animeData = [];
  String? search;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await queryData();
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future queryData() async {
    try {
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
      pageInfo
        ..clear()
        ..addAll(
          query.data!['Page']['pageInfo'],
        );
      animeData.addAll(
        List.generate(
          query.data!['Page']['media'].length,
          (index) {
            return AniData.fromJson(
              query.data!['Page']['media'][index],
              widget.type,
            );
          },
        ),
      );
      loading = false;
      setState(() {});
    } catch (e) {
      animeData.addAll([]);
    }
  }

  Future searchData() async {
    pageInfo['currentPage'] = 0;
    animeData.clear();
    selectedGenres.clear();
    if (textController.text.isNotEmpty) {
      search = textController.text;
    } else {
      tag = null;
      search = null;
    }
    await queryData();
  }

  Future updateGenre() async {
    await showModalBottomSheet(
      constraints: BoxConstraints.tightFor(width: clampDouble(MediaQuery.of(context).size.width, 0, 384)),
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(15),
          child: StatefulBuilder(
            builder: (context, setState) => Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: List.generate(
                genresList.length,
                (index) {
                  return FilterChip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    labelPadding: const EdgeInsets.all(0),
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
        );
      },
    ).then(
      (value) async {
        pageInfo.clear();
        animeData.clear();
        await queryData();
      },
    );
  }

  @override
  Widget build(context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels == notification.metrics.maxScrollExtent &&
            pageInfo['lastPage'] != pageInfo['currentPage'] &&
            !loading) {
          loading = true;
          Future.microtask(
            () async {
              await queryData();
            },
          );
        }
        return false;
      },
      child: RefreshIndicator(
        edgeOffset: 100,
        onRefresh: () => Future.microtask(
          () async {
            await queryData();
          },
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: SearchButton(
                  text: "Anilist",
                  controller: textController,
                  search: () async {
                    await searchData();
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
      ),
    );
  }
}
