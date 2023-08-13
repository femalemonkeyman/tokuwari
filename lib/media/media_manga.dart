import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';


class MangaReader extends StatelessWidget {
  final int chapter;
  final List chapters;
  final bool reverse;
  final PageController controller = PageController();
  final BaseCacheManager cache = CacheManager(
    Config(
      'MReader',
      maxNrOfCacheObjects: 15,
      stalePeriod: const Duration(minutes: 2),
    ),
  );

  MangaReader(
      {Key? key,
      required this.chapter,
      required this.chapters,
      this.reverse = false})
      : super(key: key);

  @override
  Widget build(final context) {
    return FutureBuilder<List>(
      future: chapters[chapter].call!(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            body: Stack(
              children: [
                PhotoViewGallery.builder(
                  itemCount: snapshot.data!.length,
                  allowImplicitScrolling: true,
                  scrollPhysics: const NeverScrollableScrollPhysics(),
                  pageController: controller,
                  reverse: true,
                  builder: (context, index) {
                    return PhotoViewGalleryPageOptions(
                      imageProvider: CachedNetworkImageProvider(
                        snapshot.data?[index],
                        cacheManager: cache,
                      ),
                    );
                  },
                ),
                MangaControls(
                  controller: controller,
                ),
              ],
            ),
          );
        }
        return const Column(
          children: [
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

class MangaControls extends StatefulWidget {
  final PageController controller;
  const MangaControls({required this.controller, super.key});

  @override
  State createState() => MangaControlsState();
}

class MangaControlsState extends State<MangaControls> {
  bool show = false;

  @override
  void dispose() {
    widget.controller.dispose();
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
                Positioned(
                  bottom: 0,
                  child: Text(
                    ((widget.controller.page?.toInt() ?? 0) + 1).toString(),
                  ),
                ),
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
                  width: width / 2,
                  height: height,
                  child: GestureDetector(
                    onTap: () {
                      widget.controller.jumpToPage(
                        (widget.controller.page! + 1).toInt(),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  width: width / 2,
                  height: height,
                  child: GestureDetector(
                    onTap: () {
                      widget.controller.jumpToPage(
                        (widget.controller.page! - 1).toInt(),
                      );
                    },
                  ),
                ),
                Positioned(
                  height: height / 5,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    //behavior: HitTestBehavior.opaque,
                    onTap: () => setState(
                      () => (show = !show),
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
