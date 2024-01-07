import 'dart:io';

import 'package:epubx/epubx.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:csslib/parser.dart' as cs;
import 'package:csslib/visitor.dart' as csv;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

class NovelController {
  final EpubBook epub;
  final List chapterSpans;
  double fontScale = Platform.isAndroid || Platform.isIOS ? 1 : 1.14285714;

  NovelController._(this.epub, this.chapterSpans);

  static Future<NovelController> create(String path) async {
    final epub = await compute((path) async => await EpubReader.readBook(File(path).readAsBytes()), path);
    final chapterSpans = await compute((cpub) {
      try {
        return ChapterParser.createParser(epub).parseChapters();
      } catch (e, stack) {
        print(stack);
        print(e);
      }
    }, epub);
    return NovelController._(epub, chapterSpans!);
  }

  void setFontScale(int fontSize) => fontScale = fontSize / 14;
}

class ChapterParser {
  final EpubBook epub;
  final Map<String, Map<String, String>> cssStyles;
  String currentChapterFile = '';

  ChapterParser._(this.epub, this.cssStyles);

  static ChapterParser createParser(EpubBook epub) {
    final StringBuffer css = StringBuffer();
    for (final cssValue in epub.css.values) {
      css.writeln(cssValue.Content);
    }
    return ChapterParser._(epub, parseCss(css.toString()));
  }

  static Map<String, Map<String, String>> parseCss(String css) {
    final styleSheet = cs.parse(css.toString());
    final Map<String, Map<String, String>> cssStyles = {};
    for (final node in styleSheet.topLevels) {
      if (node is csv.RuleSet) {
        final declarations = <String, String>{};
        for (final dec in node.declarationGroup.declarations) {
          final split = dec.span!.text.split(':');
          declarations[split[0].trim()] = split[1].trim();
        }
        cssStyles[node.span.text.trim()] = declarations;
      }
    }
    return cssStyles;
  }

  TextStyle tagStyle(String tag) => switch (tag) {
        'small' => const TextStyle(fontSize: 11.2),
        'sub' => const TextStyle(fontFeatures: [FontFeature.subscripts()]),
        'sup' => const TextStyle(fontFeatures: [FontFeature.superscripts()]),
        'h1' => const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        'h2' => const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        'h3' => const TextStyle(fontSize: 16.38, fontWeight: FontWeight.bold),
        'h4' => const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        'h5' => const TextStyle(fontSize: 11.62, fontWeight: FontWeight.bold),
        'h6' => const TextStyle(fontSize: 9.38, fontWeight: FontWeight.bold),
        'b' || 'strong' => const TextStyle(fontWeight: FontWeight.bold),
        'i' || 'em' => const TextStyle(fontStyle: FontStyle.italic),
        'a' => const TextStyle(color: Colors.blue),
        _ => const TextStyle(),
      };

  List<InlineSpan> parseChapters() {
    final List<InlineSpan> chapterSpans = [];
    for (final chapter in epub.Chapters) {
      currentChapterFile = epub.Chapters[1].ContentFileName; //chapter.ContentFileName;
      final document = XmlDocument.parse(epub.Chapters[1].HtmlContent);
      final html = document.getElement('html', namespace: 'http://www.w3.org/1999/xhtml');
      if (html == null) {
        throw Exception('Chapter parsing error: Chapter does not contain proper xhtml');
      }
      final htmlStyle = html.getElement('head')!.getElement('style');
      if (htmlStyle != null) {
        cssStyles.addAll(parseCss(htmlStyle.innerText));
      }
      final htmlBody = html.getElement('body');
      if (htmlBody == null) {
        throw Exception('Chapter parsing error: HTML body not found');
      }
      _parseElements(htmlBody, chapterSpans, const TextStyle());
      break;
    }
    return chapterSpans;
  }

  void _parseElements(XmlNode node, List<InlineSpan> chapterSpans, TextStyle style) {
    switch (node) {
      case XmlText(:final value):
        chapterSpans.add(
          TextSpan(text: value, style: style),
        );
      case XmlElement(:final localName):
        if (node.getAttribute('hidden') != null) {
          break;
        }
        final List<InlineSpan> childrenSpans = [];
        final name = localName.toLowerCase();
        switch (name) {
          case 'image':
          case 'img':
            final location = Uri.directory(p.dirname(currentChapterFile))
                .resolve(node.getAttribute('src') ?? node.getAttribute('href', namespace: '*')!)
                .path;
            chapterSpans.add(
              WidgetSpan(
                child: Center(
                  child: ExtendedImage.memory(
                    epub.images[location]!.Content!,
                    fit: BoxFit.cover,
                    enableMemoryCache: false,
                    clearMemoryCacheWhenDispose: true,
                  ),
                ),
              ),
            );
          case 'a':
            for (final child in node.children) {
              _parseElements(child, childrenSpans, style);
            }
            chapterSpans.add(
              WidgetSpan(
                child: GestureDetector(
                  onTap: () => print(node.getAttribute('href')),
                  child: Text.rich(
                    TextSpan(
                      children: childrenSpans,
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
              ),
            );
          default:
            for (final child in node.children) {
              if (child case XmlText(:final value) when value.trim().isEmpty) {
                print('yes');
                continue;
              }
              style = tagStyle(name);
              final value = (cssStyles[name] ?? cssStyles['.$elementClass'] ?? cssStyles['$name.$elementClass']);
              _parseElements(child, childrenSpans, style);
            }
            if (node.nextElementSibling != null) {
              //print(node.nextSibling!.nodeType);
              childrenSpans.add(TextSpan(text: '\n'));
            }
            chapterSpans.add(
              TextSpan(children: childrenSpans, style: style),
            );
        }
    }
  }

  TextStyle cssStyle(Map<String, String> values) {
  for(final MapEntry(:key, :value) in values.entries)
    switch(key)

}
}
