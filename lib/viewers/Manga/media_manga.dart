import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tokuwari/models/anidata.dart';
import 'package:tokuwari/viewers/Manga/manga_controller.dart';
import 'package:tokuwari/widgets/preload_page_view.dart';

class MangaReader extends StatefulWidget {
  final AniData manga;
  final int chapter;

  const MangaReader({super.key, required this.manga, required this.chapter});

  @override
  State createState() => MangaReaderState();
}

class MangaReaderState extends State<MangaReader> {
  late final ReaderController prefs = ReaderController(chapters: widget.manga.mediaProv, current: widget.chapter);
  bool _show = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    Future.microtask(() async {
      await prefs.load.value;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    prefs.dispose();
    super.dispose();
  }

  nextPage(details) {}

  @override
  Widget build(context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: [
          PreloadPageView.builder(
            //preloadPagesCount: prefs.twoPage ? 2 : 3,
            itemCount: prefs.pageCount + 1,
            controller: prefs.controller,
            reverse: prefs.reverse,
            pageSnapping: !prefs.isVertical,
            scrollDirection: switch (prefs.direction) {
              ReaderDirection.vertical => Axis.vertical,
              ReaderDirection.horizontal || ReaderDirection.wrong => Axis.horizontal,
            },
            itemBuilder: (context, index) {
              if (prefs.pages.isEmpty) {
                return Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text("Escape?"),
                  ),
                );
              }
              if (index > prefs.pageCount) {
                print('end');
                return Placeholder();
              }
              if (!prefs.twoPage) {
                return CachedNetworkImage(
                  imageUrl: prefs.chapter.pages[index],
                );
              } else {
                index = index * 2;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (prefs.pages.length - 1 > index)
                      Flexible(
                        child: CachedNetworkImage(
                          imageUrl: prefs.pages[index + 1],
                        ),
                      ),
                    Flexible(
                      child: CachedNetworkImage(
                        imageUrl: prefs.pages[index],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: () {
              print("Uwu");
            },
            onTapUp: (details) async {
              final left = details.globalPosition.dx < width / 3;
              final right = details.globalPosition.dx > width / 1.5;
              if ((prefs.reverse) ? left : right && !prefs.loading) {
                if (prefs.controller.page == prefs.pageCount - 1 && prefs.hasNext) {
                  await prefs.forwardChapter();
                  setState(() {});
                } else {
                  await prefs.controller.nextPage(duration: const Duration(microseconds: 1), curve: Curves.linear);
                }
              } else if ((prefs.reverse) ? right : left && !prefs.loading) {
                if (prefs.controller.page == 0 && prefs.hasPrevious) {
                  await prefs.backChapter();
                  setState(() {});
                } else {
                  await prefs.controller.previousPage(duration: const Duration(microseconds: 1), curve: Curves.linear);
                }
              } else {
                setState(() {
                  _show = !_show;
                });
              }
            },
          ),
          Column(
            children: [
              AnimatedContainer(
                height: _show ? 60 : 0,
                duration: const Duration(milliseconds: 500),
                child: AppBar(
                  backgroundColor: Colors.black87,
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.manga.title,
                        textScaler: const TextScaler.linear(0.7),
                      ),
                      Text(
                        "Ch.${prefs.chapters[prefs.current].number} ${prefs.chapters[prefs.current].title}",
                        textScaler: const TextScaler.linear(0.7),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SafeArea(
                child: AnimatedContainer(
                  height: _show ? 135 : 0,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: ProgressBar(prefs: prefs),
                      ),
                      Expanded(
                        child: Container(
                          color: Colors.black87,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                onPressed: () => showModalBottomSheet(
                                  context: context,
                                  builder: (context) => ListView.builder(
                                    itemCount: widget.manga.mediaProv.length,
                                    itemBuilder: (BuildContext context, int index) => ListTile(
                                      title: Text("Ch.${widget.manga.mediaProv[index].number}"),
                                      subtitle: Text(widget.manga.mediaProv[index].title),
                                      onTap: () async {
                                        await prefs.setChapter(index);
                                        setState(() {});
                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.format_list_numbered_rounded),
                              ),
                              PopupMenuButton(
                                offset: const Offset(100, -150),
                                icon: const Icon(Icons.chrome_reader_mode),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: const Text("Horizontal"),
                                    onTap: () => setState(
                                      () => prefs.direction = ReaderDirection.horizontal,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    child: const Text("Vertical"),
                                    onTap: () => setState(
                                      () => prefs.direction = ReaderDirection.vertical,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    child: const Text("Wrong"),
                                    onTap: () => setState(
                                      () => prefs.direction = ReaderDirection.wrong,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.tune),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final ReaderController prefs;
  const ProgressBar({super.key, required this.prefs});

  @override
  Widget build(context) {
    return Container(
      width: MediaQuery.of(context).size.width / 1.15,
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
      child: ValueListenableBuilder(
        valueListenable: prefs.page,
        builder: (context, page, _) => Directionality(
          textDirection: prefs.reverse ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: prefs.reverse ? const Icon(Icons.skip_next) : const Icon(Icons.skip_previous),
                ),
                Text((page.toInt() + 1).toString()),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: prefs.pages.isNotEmpty ? prefs.pageCount - 1 : 1,
                    divisions: prefs.pageCount <= 1 ? 1 : prefs.pageCount - 1,
                    label: ((page + 1)).round().toString(),
                    value: prefs.page.value,
                    onChanged: (value) {
                      prefs.controller.jumpToPage(
                        value.toInt(),
                      );
                    },
                  ),
                ),
                Text(prefs.pageCount.toString()),
                IconButton(
                  onPressed: () {},
                  icon: prefs.reverse ? const Icon(Icons.skip_previous) : const Icon(Icons.skip_next),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
