import 'package:anicross/anime/anime.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';
import '../block.dart';

class AnimeGrid extends StatefulWidget {
  final List data;
  const AnimeGrid({
    required this.data,
    Key? key,
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
      itemCount: widget.data.length,
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        mainAxisSpacing: 3,
        childAspectRatio: 0.70,
        crossAxisCount: Platform.isAndroid && !kIsWeb ? 2 : 3,
      ),
      itemBuilder: (context, index) {
        return Block(
          mediaList: AniEpisodes(
            id: widget.data[index]['id'].toString(),
          ),
          title: Text(
            "${widget.data[index]['title']['romaji']}",
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          image: CachedNetworkImage(
            fit: BoxFit.contain,
            imageUrl: widget.data[index]['coverImage']['extraLarge'],
            //width: MediaQuery.of(context).size.width / 2,
            //height: MediaQuery.of(context).size.width / 5,
          ),
          count: widget.data[index]['episodes'],
          score: widget.data[index]['averageScore'],
          description: widget.data[index]['description'] ?? "",
        );
      },
    );
  }
}
