import 'dart:io';

import 'package:epubx/epubx.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csslib/parser.dart' as cs;
import 'package:csslib/visitor.dart' as csv;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

class NovelController {
  final EpubBook epub;
  final List<Widget> chapters;
  double fontScale = Platform.isAndroid || Platform.isIOS ? 1 : 1.14285714;

  NovelController._(this.epub, this.chapters);

  static Future<NovelController> create(String path) async {
    final computed = await compute((final path) async {
      try {
        final epub = await EpubReader.readBook(File(path).readAsBytes());
        return (epub, ChapterParser(epub).parseChapters());
      } catch (e, stack) {
        print(stack);
        print(e);
      }
    }, path);
    // final chapterSpans = ChapterParser(epub).parseChapters();
    return NovelController._(computed!.$1, computed.$2);
  }

  void setFontScale(int fontSize) => fontScale = fontSize / 14;
}

class ChapterParser {
  final EpubBook epub;
  late Map<String, Map<String, String>> cssStyles;
  String currentChapterFile = '';

  ChapterParser(this.epub) {
    final StringBuffer css = StringBuffer();
    for (final cssValue in epub.css.values) {
      css.writeln(cssValue.Content);
    }
    cssStyles = parseCss(css.toString());
  }

  static Map<String, Map<String, String>> parseCss(String css) {
    final styleSheet = cs.parse(css.toString());
    final Map<String, Map<String, String>> cssStyles = {};
    for (final node in styleSheet.topLevels) {
      if (node is csv.FontFaceDirective) {
        print(node.span.text);
      }
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
        _ => const TextStyle(),
      };

  List<Widget> parseChapters() {
    final List<Widget> chapters = [];
    for (final chapter in epub.Chapters) {
      final List<InlineSpan> children = [];
      currentChapterFile = chapter.ContentFileName;
      final document = XmlDocument.parse(chapter.HtmlContent);
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
      _parseElements(htmlBody, children, const TextStyle());
      chapters.add(ChapterElement(text: TextSpan(children: children)));
    }
    return chapters;
  }

  void _parseElements(XmlElement node, List<InlineSpan> children, TextStyle style) {
    if (node.getAttribute('hidden') != null) return;
    final name = node.localName.toLowerCase();
    switch (node.localName.toLowerCase()) {
      // Inline Elements
      case 'image':
      case 'img':
        final location = Uri.directory(p.dirname(currentChapterFile))
            .resolve(node.getAttribute('src') ?? node.getAttribute('href', namespace: '*')!)
            .path;
        children.add(
          WidgetSpan(
            child: ExtendedImage.memory(
              epub.images[location]!.Content!,
              fit: BoxFit.cover,
              enableMemoryCache: false,
              clearMemoryCacheWhenDispose: true,
            ),
          ),
        );
      case 'svg':
        print(node.children.last);
      // block elements
      case 'div':
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
      case 'body':
      case 'section':
      case 'p':
        children.addAll(_buildWidgets(node, style));
      case 'br':
        print('no');
        children.add(const TextSpan(text: '\n'));
      case 'em':
      case 'i':
      case 'b':
      case 'span':
      case 'strong':
      case 'a':
        children.addAll(_buildWidgets(node, style));
      default:
    }
  }

  List<InlineSpan> _buildWidgets(XmlElement node, TextStyle style) {
    final List<InlineSpan> children = [];
    for (final child in node.children) {
      if (child case XmlText(:final value)) {
        if (value.trim().isEmpty) continue;
        children.add(TextSpan(text: value));
      } else if (child is XmlElement) {
        _parseElements(child, children, style);
      } else {
        print(child);
      }
    }
    return children;
  }
}

class ChapterElement extends MultiChildRenderObjectWidget {
  final InlineSpan text;
  final ElementRenderType renderType;
  ChapterElement({
    super.key,
    required this.text,
    this.renderType = ElementRenderType.block,
  }) : super(children: WidgetSpan.extractFromInlineSpan(text, TextScaler.noScaling));

  @override
  ChapterElementRenderObject createRenderObject(BuildContext context) {
    return ChapterElementRenderObject(text, textDirection: TextDirection.ltr);
  }

  @override
  void updateRenderObject(BuildContext context, covariant ChapterElementRenderObject renderObject) {
    // TODO: implement updateRenderObject
    //renderObject.markNeedsPaint();
  }
}

class TextNode extends TextSpan {
  final ElementRenderType renderType;
  const TextNode({super.text, super.style, this.renderType = ElementRenderType.block, super.children});
}

class ChapterElementRenderObject extends RenderParagraph {
  ChapterElementRenderObject(
    super.text, {
    super.textDirection = TextDirection.ltr,
  });
  @override
  void performLayout() {
    // For non-block elements, perform default layout
    super.performLayout();
  }
}

enum ElementRenderType {
  block,
  inline,
}
