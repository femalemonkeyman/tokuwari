import 'package:anicross/anime/anime_search.dart';
import 'package:anicross/manga/manga_search.dart';
import 'package:flutter/material.dart';

class SearchButton extends StatelessWidget {
  const SearchButton({Key? key, required this.text}) : super(key: key);

  final String text;

  @override
  Widget build(context) {
    return GestureDetector(
      onTap: (() => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (text == "anilist")
                  ? const AnimeSearch()
                  : (text == "mangadex")
                      ? const MangaSearch()
                      : const Scaffold(
                          body: BackButton(),
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
