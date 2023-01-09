import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'anime.dart';
import 'anime_grid.dart';

class AnimeSearch extends StatefulWidget {
  const AnimeSearch({
    Key? key,
  }) : super(key: key);

  @override
  State createState() => AnimeSearchState();
}

class AnimeSearchState extends State<AnimeSearch> {
  TextEditingController textQuery = TextEditingController();
  Widget body = Container();
  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: TextField(
              autofocus: true,
              controller: textQuery,
              onSubmitted: (query) async {
                setState(() {
                  body = GraphQLProvider(
                    client: client,
                    child: Query(
                      options: QueryOptions(
                        variables: {'search': query},
                        document: gql(listSearch),
                      ),
                      builder: (result, {refetch, fetchMore}) {
                        if (result.isNotLoading) {
                          //print(result.data)
                          return AnimeGrid(
                            data: result.data!['Page']['media'],
                          );
                        }
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                  );
                });
              },
              decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      textQuery.text = "";
                      /* Clear the search field */
                    },
                  ),
                  hintText: 'Anilist',
                  border: InputBorder.none),
            ),
          ),
        ),
      ),
      body: body,
    );
  }
}
