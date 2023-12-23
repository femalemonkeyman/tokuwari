import 'dart:io';

import 'package:epubx/epubx.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

class NovelViewerState extends State<NovelViewer> {
  EpubBook? epub;

  @override
  void initState() {
    Future.microtask(() async {
      epub = await compute((paths) async {
        final epub = await EpubReader.readBook(File(paths['path']!).readAsBytes());
        for (final chapter in epub.Chapters) {
          ChapterParser.parseChapter(chapter);
          //break;
        }
        return epub;
      }, {
        'path': widget.data.path,
      });
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (epub != null) {
      return Scaffold(
        body: Stack(
          children: [
            const BackButton(),
          ],
        ),
      );
    }
    return const Loading();
  }
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
    final chapterElements = <ChapterElement>[];

    parseChildElements(htmlBody.childElements, []);
  }

  static parseChildElements(Iterable<XmlElement> elements, List<String> classes) {
    final chapterElements = <ChapterElement>[];
    for (final child in elements) {
      final eClass = child.getAttribute('class');
      if (eClass != null) {
        classes.add(eClass);
      }
      final children = child.childElements;
      if (children.isNotEmpty) {
        parseChildElements(children, classes);
      }
      chapterElements.add(
        ChapterElement(
          classes: classes,
          type: child.localName.toLowerCase(),
          content: child.innerText,
        ),
      );
      classes.clear();
    }
    //print(chapterElements);
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
    return '$classes, $type, $content';
  }
}
