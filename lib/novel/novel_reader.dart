import 'dart:io';
import '/models/info_models.dart';
import '/novel/novel_parser.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class NovelReader extends StatefulWidget {
  final NovData data;
  const NovelReader({required this.data, super.key});

  @override
  State createState() => NovelReaderState();
}

class NovelReaderState extends State<NovelReader> {
  late final Novel novel = Novel(path: widget.data.path);
  late final String extract;
  final List<Widget> chapters = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () async {
        extract = '${(await getTemporaryDirectory()).path}/anicross-epub';
        await novel.parse();
        setState(() {
          chapters.addAll(novel.parseChapters(extract));
        });
      },
    );
  }

  @override
  void dispose() {
    novel.close();
    Directory(extract).deleteSync(recursive: true);
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
          : Stack(
              children: [
                ListView(
                  primary: true,
                  semanticChildCount: chapters.length,
                  children: chapters,
                ),
                const NovelControls(),
              ],
            ),
    );
  }
}

class NovelControls extends StatefulWidget {
  //final PageController controller;
  const NovelControls({super.key});

  @override
  State createState() => NovelControlsState();
}

class NovelControlsState extends State<NovelControls> {
  bool show = false;

  @override
  void dispose() {
    //widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: !show ? 0.0 : 1.0,
            child: Stack(
              children: [
                // Positioned(
                //   bottom: 0,
                //   child: Text(
                //       ((widget.controller.page?.toInt() ?? 0) + 1).toString(),
                //       ),
                // ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xCC000000),
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0xCC000000),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  width: width / 3,
                  height: height,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      //print("left");
                      // widget.controller.jumpToPage(
                      //   (widget.controller.page! + 1).toInt(),
                      // );
                    },
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  width: width / 3,
                  height: height,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      // widget.controller.jumpToPage(
                      //   (widget.controller.page! - 1).toInt(),
                      // );
                    },
                  ),
                ),
                Positioned(
                  height: height / 5,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => setState(
                      () => (show) ? show = false : show = true,
                    ),
                  ),
                ),
                const BackButton(),
              ],
            ),
          )
        ],
      ),
    );
  }
}
