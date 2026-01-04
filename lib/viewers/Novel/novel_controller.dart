import 'dart:io';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:epubx/epubx.dart';
import 'package:path/path.dart' as p;
import 'package:csslib/parser.dart' as cs;
import 'package:csslib/visitor.dart' as csv;
import 'package:flutter/foundation.dart';

class NovelController {
  final EpubBook epub;
  final List<EpubChapter> chapters;
  late String cssString;
  late final Map<String, Map<String, String>> cssStyles;
  int currentChapter = 0;
  double fontScale = Platform.isAndroid || Platform.isIOS ? 1 : 1.14285714;

  NovelController._(this.epub, this.chapters) {
    final StringBuffer css = StringBuffer();
    for (final cssValue in epub.css.values) {
      css.writeln(cssValue.Content);
    }
    cssString = css.toString().replaceAll(RegExp(r'^\s*(width|height)\s*:\s*[\d.]+%\s*;\s*$', multiLine: true), '');
  }

  static Future<NovelController> create(String path) async {
    final computed = await compute((String path) async {
      try {
        final epub = await EpubReader.readBook(File(path).readAsBytes());
        //final parser = ChapterParser(epub);
        return (epub, epub.Chapters);
      } catch (e, stack) {
        print(stack);
        print(e);
        rethrow;
      }
    }, path);

    return NovelController._(computed.$1, computed.$2);
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
    final styleSheet = cs.parse(css);
    final styles = <String, Map<String, String>>{};

    for (final node in styleSheet.topLevels) {
      if (node is csv.RuleSet) {
        final declarations = <String, String>{};
        for (final dec in node.declarationGroup.declarations) {
          final split = dec.span!.text.split(':');
          if (split.length == 2) {
            declarations[split[0].trim()] = split[1].trim();
          }
        }
        for (final selector in node.selectorGroup!.selectors) {
          for (final seq in selector.simpleSelectorSequences) {
            final s = seq.simpleSelector;
            String? key;
            if (s is csv.ClassSelector) {
              key = '.${s.name}';
            } else if (s is csv.IdSelector) {
              key = '#${s.name}';
            } else if (s is csv.ElementSelector) {
              key = s.name;
            }
            if (key != null) {
              styles[key] = declarations;
            }
          }
        }
      }
    }
    return styles;
  }

  List<InlineSpan> parseChapters() {
    final List<InlineSpan> chapters = [];
    for (final chapter in epub.Chapters) {
      final List<InlineSpan> children = [];
      currentChapterFile = chapter.ContentFileName;
      final document = XmlDocument.parse(chapter.HtmlContent);
      final html = document.getElement('html');

      if (html == null) {
        throw Exception('Chapter parsing error: Missing <html>');
      }

      final headStyle = html.getElement('head')?.getElement('style');
      if (headStyle != null) {
        cssStyles.addAll(parseCss(headStyle.innerText));
      }

      final body = html.getElement('body');
      if (body == null) {
        throw Exception('Chapter parsing error: Missing <body>');
      }

      _parseElements(body, children);
      chapters.add(TextSpan(children: children));
    }
    return chapters;
  }

  void _parseElements(XmlElement node, List<InlineSpan> children, [TextStyle? inheritedStyle]) {
    TextStyle mergedStyle = inheritedStyle ?? const TextStyle(fontSize: 14);
    EdgeInsets? margin;
    EdgeInsets? padding;

    final classAttr = node.getAttribute('class');
    if (classAttr != null) {
      for (final className in classAttr.split(' ')) {
        final css = cssStyles['.$className'];
        if (css == null) continue;
        mergedStyle = mergedStyle.merge(_cssToTextStyle(css));
        if (css.containsKey('margin')) margin = _parseEdgeInsets(css['margin']!);
        if (css.containsKey('padding')) padding = _parseEdgeInsets(css['padding']!);
      }
    }

    final idAttr = node.getAttribute('id');
    if (idAttr != null) {
      final css = cssStyles['#$idAttr'];
      if (css != null) mergedStyle = mergedStyle.merge(_cssToTextStyle(css));
    }

    mergedStyle = mergedStyle.merge(tagStyle(node.localName.toLowerCase()));

    final name = node.localName.toLowerCase();

    if (name == 'a') {
      final linkStyle = mergedStyle.copyWith(color: Colors.blue);
      final textSpans = _buildWidgets(node, linkStyle);
      children.add(TextSpan(children: textSpans, style: linkStyle));
      return;
    }

    if (name == 'fieldset') {
      final List<InlineSpan> inner = [];
      for (final child in node.children) {
        if (child is XmlElement) {
          _parseElements(child, inner, mergedStyle);
        }
      }
      children.add(
        WidgetSpan(
          child: Container(
            margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
            padding: padding ?? const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade700),
              borderRadius: BorderRadius.circular(4),
            ),
            child: RichText(
              text: TextSpan(style: mergedStyle, children: inner),
            ),
          ),
        ),
      );
      return;
    }

    if (name == 'ul' || name == 'ol') {
      int index = 1;
      for (final li in node.findElements('li')) {
        final bullet = name == 'ul' ? '\n• ' : '\n${index++}. ';
        final bulletChildren = [TextSpan(text: bullet, style: mergedStyle)];
        _parseElements(li, bulletChildren, mergedStyle);
        children.add(TextSpan(children: bulletChildren, style: mergedStyle));
      }
      return;
    }

    if (name == 'img' || name == 'image' || name == 'svg') {
      final location = Uri.directory(p.dirname(currentChapterFile)).resolve(node.getAttribute('src') ?? '').path;
      final imageData = epub.images[location]?.Content;
      if (imageData != null) {
        print(padding);
        children.add(
          WidgetSpan(
            child: Container(
              margin: margin ?? EdgeInsets.zero,
              padding: padding ?? EdgeInsets.zero,
              child: Center(child: Image.memory(imageData, fit: BoxFit.cover)),
            ),
          ),
        );
      }
      return;
    }

    final textSpans = _buildWidgets(node, mergedStyle);

    final blockElements = {'p', 'div', 'section', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'br'};

    if (margin != null && margin.top > 0) {
      children.add(WidgetSpan(child: SizedBox(height: margin.top)));
    }

    if (blockElements.contains(name)) {
      children.add(const TextSpan(text: '\n'));
    }

    children.add(TextSpan(children: textSpans, style: mergedStyle));
  }

  List<InlineSpan> _buildWidgets(XmlElement node, TextStyle inheritedStyle) {
    final List<InlineSpan> children = [];
    for (final child in node.children) {
      if (child is XmlText) {
        final text = child.value;
        if (text.trim().isNotEmpty) {
          children.add(TextSpan(text: text, style: inheritedStyle));
        }
      } else if (child is XmlElement) {
        _parseElements(child, children, inheritedStyle);
      }
    }
    return children;
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

  TextStyle _cssToTextStyle(Map<String, String> css) {
    TextStyle style = const TextStyle();
    for (final entry in css.entries) {
      switch (entry.key.trim()) {
        case 'font-size':
          final fontSizeValue = entry.value.trim();
          if (fontSizeValue.endsWith('em')) {
            final em = double.tryParse(fontSizeValue.replaceAll('em', '').trim());
            if (em != null) {
              style = style.copyWith(fontSize: 14 * em);
            }
          } else if (fontSizeValue.endsWith('px')) {
            final px = double.tryParse(fontSizeValue.replaceAll('px', '').trim());
            if (px != null) {
              style = style.copyWith(fontSize: px);
            }
          }
          break;
        case 'font-weight':
          if (entry.value.trim() == 'bold') style = style.copyWith(fontWeight: FontWeight.bold);
        case 'font-style':
          if (entry.value.trim() == 'italic') style = style.copyWith(fontStyle: FontStyle.italic);
        case 'color':
          style = style.copyWith(color: _parseColor(entry.value));
      }
    }
    return style;
  }

  Color? _parseColor(String value) {
    try {
      final hex = value.replaceAll('#', '').trim();
      if (hex.length == 6) return Color(int.parse('0xFF$hex'));
      if (hex.length == 3) {
        final r = hex[0] * 2;
        final g = hex[1] * 2;
        final b = hex[2] * 2;
        return Color(int.parse('0xFF$r$g$b'));
      }
    } catch (_) {}
    return null;
  }
}

EdgeInsets _parseEdgeInsets(String value) {
  final parts = value
      .replaceAll(RegExp(r'px|em'), '')
      .split(RegExp(r'\s+'))
      .map(double.tryParse)
      .whereType<double>()
      .toList();
  if (parts.length == 1) {
    return EdgeInsets.all(parts[0]);
  } else if (parts.length == 2) {
    return EdgeInsets.symmetric(vertical: parts[0], horizontal: parts[1]);
  } else if (parts.length == 3) {
    return EdgeInsets.fromLTRB(parts[1], parts[0], parts[1], parts[2]);
  } else if (parts.length == 4) {
    return EdgeInsets.fromLTRB(parts[3], parts[0], parts[1], parts[2]);
  }
  return EdgeInsets.zero;
}
