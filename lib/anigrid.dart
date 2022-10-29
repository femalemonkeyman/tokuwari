import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:universal_io/io.dart';
import 'anime.dart';
import 'epub.dart';
import 'manga.dart';

class AniGrid extends StatefulWidget {
  final List data;
  final String place;
  const AniGrid({Key? key, required this.data, required this.place})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => AniGridState();
}

class AniGridState extends State<AniGrid> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GridView.builder(
      controller: ScrollController(),
      //controller: ScrollController(),
      itemCount: widget.data.length,
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Platform.isAndroid && !kIsWeb ? 2 : 4,
          crossAxisSpacing: 7),
      itemBuilder: (context, index) {
        switch (widget.place) {
          case "anilist":
            {
              return Block(
                id: widget.data[index]['id'].toString(),
                title: widget.data[index]['title']['romaji'],
                image: widget.data[index]['coverImage']['extraLarge'],
                count: widget.data[index]['episodes'],
                place: widget.place,
                score: widget.data[index]['averageScore'],
                description: widget.data[index]['description'] ?? "",
              );
            }
          case "mangadex":
            {
              return Block(
                title: widget.data[index]['attributes']['title'][widget
                    .data[index]['attributes']['title'].keys
                    .elementAt(0)],
                image:
                    "${"${"https://uploads.mangadex.org/covers/" + widget.data[index]['id']}/" + widget.data[index]['relationships'][widget.data[index]['relationships'].indexWhere((i) => i['type'] == "cover_art")]['attributes']['fileName']}.512.jpg",
                description:
                    (widget.data[index]['attributes']['description'].length ==
                            0)
                        ? "No description provided."
                        : widget.data[index]['attributes']['description']['en'],
                place: widget.place,
                id: widget.data[index]['id'],
                count: int.tryParse(
                  widget.data[index]['attributes']['lastChapter'] ?? "",
                ),
              );
            }
          case "local novels":
            {
              return Block(
                title: widget.data[index]['title'],
                place: "local novels",
                description: "",
                image: File(widget.data[index]['image']),
                file: widget.data[index]['file'],
              );
            }
        }
        return Container();
        //data[index]['media'] ??= data[index];
      },
    );
  }
}

class Block extends StatelessWidget {
  final String title;
  final dynamic image;
  final int? count;
  final int? score;
  final String place;
  final String description;
  final String id;
  final String? file;

  const Block(
      {Key? key,
      required this.title,
      this.image,
      this.count,
      this.score,
      required this.place,
      required this.description,
      this.id = "",
      this.file})
      : super(key: key);
  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () {
        if (place != "local novels") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return Scaffold(
                  body: SingleChildScrollView(
                    child: SafeArea(
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.topLeft,
                            child: BackButton(),
                          ),
                          Row(
                            children: [
                              const Spacer(),
                              Flexible(
                                child: Text(title),
                              ),
                              const Spacer(),
                              Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      right: 20, bottom: 40),
                                  child: CachedNetworkImage(
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    height:
                                        MediaQuery.of(context).size.width / 2.5,
                                    imageUrl: image,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              description,
                            ),
                          ),
                          if (place == "mangadex")
                            MangaChapters(
                              id: id,
                            ),
                          if (place == "anilist")
                            AniEpisodes(
                              id: id,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NovelReader(
                title: title,
                file: file,
              ),
            ),
          );
        }
      },
      child: Card(
        borderOnForeground: false,
        color: Colors.black,
        shadowColor: Colors.purple,
        elevation: 10,
        child: Column(
          children: [
            Expanded(
              flex: 50,
              child: (place != "local novels")
                  ? CachedNetworkImage(
                      imageUrl: image,
                    )
                  : Image.file(
                      image,
                      cacheWidth: 200,
                    ),
            ),
            const Spacer(),
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const Spacer(),
            Row(
              children: [
                const Spacer(),
                if (count != null || place == "anilist")
                  Text(
                    place == "anilist"
                        ? "Episodes: ${count ?? "n/a"}"
                        : "Chapters: ${count ?? "n/a"}",
                  ),
                const Spacer(
                  flex: 2,
                ),
                if (score != null)
                  Text(
                    "Score: $score",
                  ),
                const Spacer(),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
