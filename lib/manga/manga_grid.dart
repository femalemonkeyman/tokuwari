import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

import 'manga.dart';

class MangaGrid extends StatefulWidget {
  final List data;
  const MangaGrid({Key? key, required this.data}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MangaGridState();
}

class MangaGridState extends State<MangaGrid>
    with AutomaticKeepAliveClientMixin {
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
        return Block(
          title: widget.data[index]['attributes']['title']
              [widget.data[index]['attributes']['title'].keys.elementAt(0)],
          image:
              "${"${"https://uploads.mangadex.org/covers/" + widget.data[index]['id']}/" + widget.data[index]['relationships'][widget.data[index]['relationships'].indexWhere((i) => i['type'] == "cover_art")]['attributes']['fileName']}.512.jpg",
          description:
              (widget.data[index]['attributes']['description'].length == 0)
                  ? "No description provided."
                  : widget.data[index]['attributes']['description']['en'],
          id: widget.data[index]['id'],
          count: int.tryParse(
            widget.data[index]['attributes']['lastChapter'] ?? "",
          ),
        );
      },
    );
  }
}

class Block extends StatelessWidget {
  final String title;
  final dynamic image;
  final int? count;

  final String description;
  final String id;

  const Block({
    Key? key,
    required this.title,
    this.image,
    this.count,
    required this.description,
    this.id = "",
  }) : super(key: key);
  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () {
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
                                  width: MediaQuery.of(context).size.width / 2,
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
                        MangaChapters(
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
                child: CachedNetworkImage(
                  imageUrl: image,
                )),
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
                if (count != null)
                  Text(
                    "Chapters: ${count ?? "n/a"}",
                  ),
                const Spacer(
                  flex: 2,
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
