import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

import 'epub.dart';

class NovelGrid extends StatefulWidget {
  final List data;

  const NovelGrid({Key? key, required this.data}) : super(key: key);

  @override
  State<StatefulWidget> createState() => NovelGridState();
}

class NovelGridState extends State<NovelGrid>
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
            title: widget.data[index]['title'],
            description: "",
            image: File(widget.data[index]['image']),
            file: widget.data[index]['file'],
          );
        });
  }
}

class Block extends StatelessWidget {
  final String title;
  final dynamic image;
  final String description;
  final String? file;

  const Block(
      {Key? key,
      required this.title,
      this.image,
      required this.description,
      this.file})
      : super(key: key);
  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NovelReader(
              title: title,
              file: file,
            ),
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
              child: Image.file(
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
          ],
        ),
      ),
    );
  }
}
