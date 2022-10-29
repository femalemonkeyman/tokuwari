import 'package:flutter/material.dart';
import 'package:anicross/anigrid.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'manga.dart';

class SearchButton extends StatelessWidget {
  const SearchButton({Key? key, required this.text}) : super(key: key);

  final String text;

  @override
  Widget build(context) {
    return GestureDetector(
      onTap: (() => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AniSearch(
                place: text,
              ),
            ),
          )),
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 10),
        margin: const EdgeInsets.only(bottom: 20, top: 20),
        height: 45,
        width: MediaQuery.of(context).size.width / 1.5,
        decoration: BoxDecoration(
          color: Colors.blueGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.search),
            const Spacer(),
            const Text("Search"),
            const Spacer(
              flex: 95,
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
      ),
    );
  }
}

class AniSearch extends StatefulWidget {
  final String place;

  const AniSearch({Key? key, required this.place}) : super(key: key);

  @override
  State createState() => AniSearchState();
}

class AniSearchState extends State<AniSearch> {
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
                if (widget.place == "anilist") {
                  // body = GraphQLProvider(
                  //   client: client,
                  //   child: Query(
                  //     options: QueryOptions(
                  //       variables: {'search': query},
                  //       document: gql(listSearch),
                  //     ),
                  //     builder: (result, {refetch, fetchMore}) {
                  //       if (result.isNotLoading) {
                  //         //print(result.data)
                  //         return AniGrid(
                  //           data: result.data!['Page']['media'],
                  //           place: "anilist",
                  //         );
                  //       }
                  //       return const Center(
                  //         child: CircularProgressIndicator(),
                  //       );
                  //     },
                  //   ),
                  // );
                } else {
                  var data = await dexSearch(query);
                  //print(data['data'][0]);
                  body = AniGrid(
                    data: data,
                    place: "mangadex",
                  );
                }
                setState(() {});
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
                  hintText: 'Search ${widget.place}',
                  border: InputBorder.none),
            ),
          ),
        ),
      ),
      body: body,
    );
  }
}
