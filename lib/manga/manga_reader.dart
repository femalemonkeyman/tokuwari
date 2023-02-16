import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MangaReader extends StatelessWidget {
  final String current;
  final List chapters;
  final int index;
  final bool reverse;
  final PageController controller = PageController();

  MangaReader(
      {Key? key,
      required this.current,
      required this.index,
      required this.chapters,
      this.reverse = false})
      : super(key: key);

  dexPages(chapterId, reversed) async {
    List pages = [];
    var json =
        await Dio().get("https://api.mangadex.org/at-home/server/$chapterId");
    for (var page in json.data['chapter']['data']) {
      pages.add(
          "https://uploads.mangadex.org/data/${json.data['chapter']['hash']}/$page");
    }
    if (reversed) {
      pages = pages.reversed.toList();
    }
    return pages;
  }

  @override
  Widget build(context) {
    return FutureBuilder<dynamic>(
      future: dexPages(current, reverse),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (reverse) {}
          return Column(
            children: [
              const BackButton(),
              Expanded(
                  child: Stack(
                children: [
                  RawKeyboardListener(
                    onKey: (event) {
                      //print(event.isKeyPressed(LogicalKeyboardKey.arrowLeft));
                      if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
                        controller.jumpToPage(controller.page!.toInt() + 1);
                      } else if (event
                          .isKeyPressed(LogicalKeyboardKey.arrowRight)) {
                        controller.jumpToPage(controller.page!.toInt() - 1);
                      }
                    },
                    focusNode: FocusNode(),
                    child: PageView.builder(
                      controller: controller,
                      allowImplicitScrolling: true,
                      reverse: true,
                      //preloadPagesCount: 3,
                      //scrollDirection: Axis.horizontal,
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) {
                        return InteractiveViewer(
                          child: Stack(
                            children: [
                              Center(
                                child: CachedNetworkImage(
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  imageUrl: snapshot.data?[index],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Center(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              controller
                                  .jumpToPage(controller.page!.toInt() + 1);
                            },
                          ),
                        ),
                        const Spacer(),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              controller
                                  .jumpToPage(controller.page!.toInt() - 1);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )),
            ],
          );
        }
        return Column(
          children: const [
            Align(
              alignment: Alignment.topLeft,
              child: BackButton(),
            ),
            Spacer(),
            Center(
              child: CircularProgressIndicator(),
            ),
            Spacer()
          ],
        );
      },
    );
  }
}
