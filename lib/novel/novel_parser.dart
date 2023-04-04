import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml2json/xml2json.dart';

class Novel {
  final String path;
  late final Archive archive;
  late final InputFileStream input;
  String? root;
  Map? metadata;
  Map? content;
  Map? spine;
  Map? toc;
  String? title;
  String? cover;

  final Xml2Json xml2json = Xml2Json();

  Novel({
    required this.path,
  }) {
    input = InputFileStream(path);
    archive = ZipDecoder().decodeBuffer(input);
  }

  Future parse() async {
    xml2json.parse(
      utf8.decode(
        archive.findFile("META-INF/container.xml")!.content,
      ),
    );
    root = jsonDecode(
      xml2json.toGData(),
    )['container']['rootfiles']['rootfile']['full-path'];
    xml2json.parse(
      utf8.decode(
        archive
            .findFile(
              root!,
            )
            ?.content,
      ),
    );
    content = jsonDecode(
          xml2json.toGData(),
        )['package'] ??
        jsonDecode(
          xml2json.toGData(),
        )['opf\$package'];
    content?['metadata'] ??= content?['opf\$metadata'];
    content?['manifest'] ??= content?['opf\$manifest'];
    content?['spine'] ??= content?['opf\$spine'];
    content?['manifest']['item'] ??= content?['manifest']['opf\$item'];
    if (content?['metadata']?['dc\$title'] is List) {
      content?['metadata']['dc\$title'] =
          content?['metadata']?['dc\$title']?[0];
    }

    metadata = content?['metdata'];
    spine = content?['spine'];
    title = content?['metadata']?['dc\$title']?['\$t'];
  }

  List<Widget> parseChapters() {
    List<Widget> chapters = [];
    for (Map s in spine!['itemref']) {
      for (Map c in content!['manifest']['item']) {
        if (c.containsValue(s['idref'])) {
          chapters.add(
            HtmlWidget(
              utf8.decode(
                archive.findFile("OEBPS/${c['href']}")?.content,
              ),
              renderMode: const ListViewMode(
                primary: false,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
              ),
            ),
          );
        }
      }
    }
    return chapters;
  }

  writeCover() async {
    final Directory documents = await getApplicationDocumentsDirectory();
    String imagePath = "";
    for (Map i in (content?['manifest']['item'])) {
      if (i.toString().toLowerCase().contains("cover") &&
          !i.toString().toLowerCase().contains("html")) {
        imagePath =
            '${documents.path}/.anicross/$title-${i['href'].split('/').last}';
        //print(imagePath);
        await (Command()
              ..decodeImage(
                (archive.findFile(
                          '${root?.split("/")[0]}/${i['href']}',
                        ) ??
                        archive.findFile(
                          '${i['href']}'.replaceAll("../", ""),
                        ))!
                    .content,
              )
              ..copyResize(
                height: 720,
              )
              ..writeToFile(imagePath))
            .executeThread();
        break;
      }
    }
    cover = imagePath;
  }

  void close() => input.close();
}
