import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:tokuwari/models/chapter.dart';
import 'package:tokuwari/models/media_prov.dart';

enum ReaderDirection {
  vertical,
  horizontal,

  ///Please place manga in front of mirror and re-evaluate yourself
  wrong,
}

class ReaderController {
  final PageController controller = PageController();
  final List<MediaProv> chapters;
  final ValueNotifier<double> page = ValueNotifier<double>(0.0);
  late CancelableOperation load = CancelableOperation.fromFuture(fetch());
  bool twoPage = true;
  Chapter chapter = const Chapter(pages: []);
  ReaderDirection direction = ReaderDirection.horizontal;
  int current;
  bool loading = false;

  ReaderController({required this.chapters, this.current = 0}) {
    controller.addListener(() {
      if (!loading) {
        page.value = controller.page!;
      }
    });
  }

  bool get hasNext => current != chapters.length - 1;
  bool get hasPrevious => current > 0;
  bool get reverse => direction != ReaderDirection.horizontal ? false : true;
  List get pages => chapter.pages;
  bool get isVertical => direction == ReaderDirection.vertical;
  int get pageCount => !twoPage || isVertical ? chapter.pages.length : (chapter.pages.length / 2).ceil();

  Future<void> fetch() async {
    chapter = await chapters[current].call!();
  }

  Future<void> forwardChapter() async {
    loading = true;
    current++;
    load = CancelableOperation.fromFuture(fetch());
    await load.value;
    page.value = 0;
    controller.jumpToPage(page.value.toInt());
    loading = false;
  }

  Future<void> backChapter() async {
    loading = true;
    current--;
    load = CancelableOperation.fromFuture(fetch());
    await load.value;
    page.value = pageCount - 1;
    controller.jumpToPage(page.value.toInt());
    loading = false;
  }

  Future<void> setChapter(final value) async {
    loading = true;
    current = value;
    load = CancelableOperation.fromFuture(fetch());
    await load.value;
    page.value = 0;
    controller.jumpToPage(page.value.toInt());
    loading = false;
  }

  void dispose() {
    controller.dispose();
    page.dispose();
    load.cancel();
  }
}
