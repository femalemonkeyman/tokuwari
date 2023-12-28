import 'dart:io';

import 'package:epubx/epubx.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:path/path.dart' as p;
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tokuwari/widgets/loading.dart';
import 'package:xml/xml.dart';
import 'package:tokuwari_models/info_models.dart';

class NovelViewer extends StatefulWidget {
  final NovData data;

  const NovelViewer({super.key, required this.data});

  @override
  State createState() => NovelViewerState();
}

class NovelViewerState extends State<NovelViewer> with AutomaticKeepAliveClientMixin {
  EpubBook? epub;
  late List chapterWidgets;

  @override
  void initState() {
    Future.microtask(() async {
      epub = await compute((path) async {
        final epub = await EpubReader.readBook(File(path).readAsBytes());
        //for (final chapter in epub.Chapters) {}
        //ChapterParser.parseChapter(epub.Chapters[8]);
        return epub;
      }, widget.data.path);
      chapterWidgets = await compute((cpub) {
        final chapterWidgets = [];
        for (final chapter in cpub.Chapters) {
          final document = XmlDocument.parse(chapter.HtmlContent);
          final html = document.getElement('html', namespace: 'http://www.w3.org/1999/xhtml');
          chapterWidgets.add(
            HtmlWidget(
              html!.getElement('body').toString(),
              buildAsync: false,
              customWidgetBuilder: (element) {
                if (element.localName == 'img') {
                  return InlineCustomWidget(
                    child: ExtendedImage.memory(
                      cpub.images[element.attributes['src']!.replaceAll('../', '')]!.Content!,
                      width: double.infinity,
                    ),
                  );
                }
              },
              renderMode: RenderMode.sliverList,
            ),
          );
        }
        return chapterWidgets;
      }, epub!);
      if (mounted) {
        setState(() {});
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (epub != null) {
      return Scaffold(
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: PageView.builder(
                itemCount: chapterWidgets.length,
                itemBuilder: (context, index) => CustomScrollView(
                  slivers: [
                    chapterWidgets[index],
                  ],
                ),
              ),
            ),
            const BackButton(),
          ],
        ),
      );
    }
    return const Loading();
  }

  @override
  bool get wantKeepAlive => true;
}

class ChapterParser {
  static parseChapter(EpubChapter chapter) {
    final document = XmlDocument.parse(chapter.HtmlContent);
    final html = document.getElement('html', namespace: 'http://www.w3.org/1999/xhtml');
    if (html == null) {
      throw Exception('Chapter parsing error: Chapter does not contain xhtml');
    }
    // final htmlHead = html.getElement('head');
    // if (htmlHead == null) {
    //   throw Exception('Chapter parsing error: HTML head not found');
    // }
    // parseHead(htmlHead);
    final htmlBody = html.getElement('body');
    if (htmlBody == null) {
      throw Exception('Chapter parsing error: HTML body not found');
    }
    parseBody(htmlBody);
  }

  static parseHead(XmlElement htmlHead) {}

  static parseBody(XmlElement htmlBody) {
    final chapterElements = parseChildElements(htmlBody.childElements, [], []);
    print(chapterElements.length);
  }

  static parseChildElements(Iterable<XmlElement> elements, List<String> classes, List<ChapterElement> chapterElements) {
    for (final child in elements) {
      final eClass = child.getAttribute('class');
      if (eClass != null) {
        classes.add(eClass);
      }
      final children = child.childElements;
      if (children.isNotEmpty) {
        parseChildElements(children, classes, chapterElements);
      }
      if (children.isEmpty) {
        chapterElements.add(
          ChapterElement(
            classes: classes,
            type: child.localName.toLowerCase(),
            content: child.innerText.trim(),
          ),
        );
        if (eClass != null && classes.isNotEmpty) {
          classes.removeLast();
        }
      }
    }
    return chapterElements.reversed;
  }
}

class ChapterContent {
  ChapterContent();
}

class ChapterElement {
  final List classes;
  final String type;
  final String content;

  ChapterElement({
    required this.classes,
    required this.type,
    required this.content,
  });

  @override
  String toString() {
    return '$classes, $type ';
  }
}
