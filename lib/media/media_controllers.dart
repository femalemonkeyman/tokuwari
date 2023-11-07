import 'package:async/async.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:tokuwari_models/info_models.dart';

enum ReaderDirection {
  vertical,
  horizontal,

  ///Please place manga in front of mirror and re-evaluate yourself
  wrong,
}

class ReaderController {
  final List<MediaProv> chapters;
  final PreloadPageController controller;
  late CancelableOperation load = CancelableOperation.fromFuture(fetch());
  Chapter chapter = const Chapter(pages: []);
  ReaderDirection direction = ReaderDirection.horizontal;
  int current;
  bool loading = false;

  ReaderController({required this.chapters, required this.controller, this.current = 0});

  bool get hasNext => current != chapters.length - 1;
  bool get hasPrevious => current > 0;
  bool get reverse => (direction == ReaderDirection.wrong) ? true : false;

  Future<void> fetch() async {
    chapter = await chapters[current].call!();
  }

  Future<void> changeChapter(final bool forward) async {
    loading = true;
    (forward) ? current++ : current--;
    load = CancelableOperation.fromFuture(fetch());
    await load.value.then((value) => controller.jumpToPage((forward) ? 0 : chapter.pages.length - 1));
    loading = false;
  }

  void dispose() {
    load.cancel();
  }
}
