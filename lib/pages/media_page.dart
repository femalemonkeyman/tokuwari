import 'dart:ui';
import 'package:isar/isar.dart';
import 'package:tokuwari/models/anidata.dart';

import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import 'package:tokuwari/models/filter.dart';
import 'package:tokuwari/models/settings.dart';
import '../widgets/search_button.dart';
import '../widgets/grid.dart';

const qString = """
query (\$page: Int!, \$type: MediaType, \$tag: String, \$search: String, \$genre: [String], \$adult: Boolean)
  {
  Page(perPage: 50, page: \$page) {
    pageInfo {
      hasNextPage
      lastPage
      total
      currentPage
    },
    media(sort: [TRENDING_DESC], type: \$type, search: \$search, genre_in: \$genre, tag: \$tag, isAdult: \$adult) {
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

class AniPage extends StatefulWidget {
  final String? tag;
  final String type;
  const AniPage({super.key, required this.type, this.tag});

  @override
  State createState() => AniPageState();
}

class AniPageState extends State<AniPage> {
  static final client = GraphQLClient(
    cache: GraphQLCache(),
    link: HttpLink("https://graphql.anilist.co/", defaultHeaders: {
      'referer': 'https://anilist.co/',
      'origin': 'https://anilist.co',
      'user-agent':
          'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
    }),
  );
  final isar = Isar.get(name: "tokudb", schemas: [SettingsSchema]);
  final TextEditingController textController = TextEditingController();
  final List<String> selectedGenres = [];
  late String? tag = widget.tag;
  final Map pageInfo = {};
  final List<AniData> animeData = [];
  AniFilter filter = AniFilter();
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
          document: gql(qString),
          variables: {
            "page": (pageInfo.isEmpty) ? 1 : pageInfo['currentPage'] + 1,
            'type': widget.type.toUpperCase(),
            'search': search,
            "genre": (selectedGenres.isNotEmpty) ? selectedGenres : null,
            "tag": tag,
            if (isar.settings.get(1)?.isNsfw != true) 'adult': false,
          },
        ),
      );
      if (query.hasException) {
        print(query.exception);
      }
      setState(() {
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
      });
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
                AniFilter.genresList.length,
                (index) {
                  return FilterChip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    labelPadding: const EdgeInsets.all(0),
                    selected: selectedGenres.contains(
                      AniFilter.genresList[index],
                    ),
                    label: Text(
                      AniFilter.genresList[index],
                    ),
                    onSelected: (value) => setState(
                      () {
                        if (value) {
                          selectedGenres.add(AniFilter.genresList[index]);
                        } else {
                          selectedGenres.remove(AniFilter.genresList[index]);
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
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SearchButton(
                text: "Anilist",
                controller: textController,
                search: () async {
                  await searchData();
                },
              ),
              SliverToBoxAdapter(
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () => updateGenre(),
                      child: const Text(
                        "Filter by genre",
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
      ),
    );
  }
}
