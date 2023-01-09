import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';
import 'anime.dart';

class AnimeGrid extends StatefulWidget {
  final List data;
  const AnimeGrid({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => AnimeGridState();
}

class AnimeGridState extends State<AnimeGrid>
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
          id: widget.data[index]['id'].toString(),
          title: widget.data[index]['title']['romaji'],
          image: widget.data[index]['coverImage']['extraLarge'],
          count: widget.data[index]['episodes'],
          score: widget.data[index]['averageScore'],
          description: widget.data[index]['description'] ?? "",
        );
      },
    );
  }
}

class Block extends StatelessWidget {
  final String title;
  final dynamic image;
  final int? count;
  final int? score;
  final String description;
  final String id;

  const Block({
    Key? key,
    required this.title,
    this.image,
    this.count,
    this.score,
    required this.description,
    this.id = "",
  }) : super(key: key);
  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () {
        {
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
              child: CachedNetworkImage(
                imageUrl: image,
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
                Text("Episodes: ${count ?? "n/a"}"),
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
