import 'package:flutter/material.dart';
import 'manga.dart';
import 'manga_grid.dart';

class MangaSearch extends StatefulWidget {
  const MangaSearch({Key? key}) : super(key: key);

  @override
  State createState() => MangaSearchState();
}

class MangaSearchState extends State<MangaSearch> {
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
                var data = await dexSearch(query);
                setState(() {
                  body = MangaGrid(
                    data: data,
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
                  hintText: 'Mangadex',
                  border: InputBorder.none),
            ),
          ),
        ),
      ),
      body: body,
    );
  }
}
