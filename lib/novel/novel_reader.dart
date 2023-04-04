import 'package:anicross/models/info_models.dart';
import 'package:anicross/novel/novel_parser.dart';
import 'package:flutter/material.dart';

class NovelReader extends StatefulWidget {
  final AniData data;
  const NovelReader({required this.data, super.key});

  @override
  State createState() => NovelReaderState();
}

class NovelReaderState extends State<NovelReader> {
  late final Novel novel = Novel(path: widget.data.mediaId!);
  List<Widget> chapters = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () async {
        await novel.parse();
        chapters = novel.parseChapters();
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    novel.close();
    super.dispose();
  }

  @override
  Widget build(context) {
    return Scaffold(
      body: (chapters.isEmpty)
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  child: const Text("Escape?"),
                  onPressed: () => Navigator.maybePop(context),
                ),
                const Center(
                  child: CircularProgressIndicator(),
                )
              ],
            )
          : ListView(
              primary: true,
              semanticChildCount: chapters.length,
              children: chapters,
            ),
    );
  }
}
