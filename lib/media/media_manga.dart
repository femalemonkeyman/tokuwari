import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:tokuwari/media/media_controllers.dart';
import 'package:tokuwari_models/info_models.dart';

class MangaReader extends StatefulWidget {
  final AniData manga;
  final int chapter;

  const MangaReader({super.key, required this.manga, required this.chapter});

  @override
  State createState() => MangaReaderState();
}

class MangaReaderState extends State<MangaReader> {
  final PreloadPageController controller = PreloadPageController();
  late final ReaderController prefs =
      ReaderController(chapters: widget.manga.mediaProv, current: widget.chapter, controller: controller);
  bool _show = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await prefs.fetch();
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    prefs.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    return Scaffold(
      body: Stack(
        children: [
          PreloadPageView.builder(
            preloadPagesCount: 3,
            itemCount: prefs.chapter.pages.length,
            controller: controller,
            reverse: prefs.reverse,
            scrollDirection: switch (prefs.direction) {
              ReaderDirection.vertical => Axis.vertical,
              ReaderDirection.horizontal || ReaderDirection.wrong => Axis.horizontal,
            },
            itemBuilder: (context, index) {
              if (prefs.chapter.pages.length > index) {
                return ExtendedImage.network(
                  prefs.chapter.pages[index],
                );
              }
              return const SizedBox.expand();
            },
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details) async {
              final width = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < width / 3 && !prefs.loading) {
                if (controller.page == prefs.chapter.pages.length - 1 && prefs.hasNext) {
                  await prefs.changeChapter(true);
                } else {
                  controller.nextPage(duration: const Duration(microseconds: 1), curve: Curves.linear);
                }
              } else if (details.globalPosition.dx > width / 1.5 && !prefs.loading) {
                if (controller.page == 0 && prefs.hasPrevious) {
                  await prefs.changeChapter(false);
                } else {
                  controller.previousPage(duration: const Duration(microseconds: 1), curve: Curves.linear);
                }
              } else {
                setState(() {
                  _show = !_show;
                });
              }
            },
            child: Column(
              children: [
                AnimatedContainer(
                  height: _show ? 56 : 0,
                  duration: const Duration(milliseconds: 500),
                  child: AppBar(),
                ),
                const Spacer(),
                AnimatedContainer(
                  height: _show ? 56 : 0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
