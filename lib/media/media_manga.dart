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
            reverse: !prefs.reverse,
            scrollDirection: switch (prefs.direction) {
              ReaderDirection.vertical => Axis.vertical,
              ReaderDirection.horizontal || ReaderDirection.wrong => Axis.horizontal,
            },
            itemBuilder: (context, index) {
              if (prefs.chapter.pages.length >= index) {
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
              if (prefs.loading) return;
              final width = MediaQuery.of(context).size.width;
              final left = details.globalPosition.dx < width / 3;
              final right = details.globalPosition.dx > width / 1.5;
              if ((prefs.reverse) ? right : left) {
                if (controller.page == prefs.chapter.pages.length - 1 && prefs.hasNext) {
                  await prefs.changeChapter(true);
                } else {
                  controller.nextPage(duration: const Duration(microseconds: 1), curve: Curves.linear);
                }
              } else if ((prefs.reverse) ? left : right) {
                if (controller.page == 0 && prefs.hasPrevious) {
                  await prefs.changeChapter(false);
                } else {
                  controller.previousPage(duration: const Duration(microseconds: 1), curve: Curves.linear);
                }
              } else {
                _show = !_show;
              }
              setState(() {});
            },
          ),
          Column(
            children: [
              AnimatedContainer(
                height: _show ? 56 : 0,
                duration: const Duration(milliseconds: 500),
                child: AppBar(),
              ),
              const Spacer(),
              AnimatedContainer(
                height: _show ? 40 : 0,
                duration: const Duration(milliseconds: 500),
                child: ProgressBar(prefs: prefs),
              ),
              AnimatedContainer(
                height: _show ? 100 : 0,
                duration: const Duration(milliseconds: 500),
                child: DraggableScrollableSheet(
                  initialChildSize: 0.5,
                  minChildSize: 0.5,
                  maxChildSize: 1,
                  builder: (context, controller) {
                    return Container(
                      color: Colors.blue,
                      child: ListView(
                        controller: controller,
                        children: [
                          ListTile(
                            title: Text('UwU'),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProgressBar extends StatefulWidget {
  final ReaderController prefs;
  const ProgressBar({super.key, required this.prefs});

  @override
  State createState() => ProgressBarState();
}

class ProgressBarState extends State<ProgressBar> {
  late double page = widget.prefs.controller.page ?? 0;

  @override
  void initState() {
    super.initState();
    widget.prefs.controller.addListener(() => setState(
          () {
            page = widget.prefs.controller.page!;
          },
        ));
  }

  @override
  Widget build(context) {
    return Directionality(
      textDirection: widget.prefs.reverse ? TextDirection.ltr : TextDirection.rtl,
      child: Slider(
        min: 0,
        max: widget.prefs.chapter.pages.isNotEmpty ? widget.prefs.chapter.pages.length.toDouble() - 1 : 1,
        divisions: (widget.prefs.chapter.pages.isEmpty) ? 1 : widget.prefs.chapter.pages.length,
        label: ((widget.prefs.controller.page ?? 0) + 1).round().toString(),
        value: page,
        onChanged: (value) => widget.prefs.controller.jumpToPage(
          value.toInt(),
        ),
      ),
    );
  }
}
