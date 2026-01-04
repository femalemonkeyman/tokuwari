import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:path/path.dart' as p;
import 'package:tokuwari/models/novdata.dart';
import 'package:tokuwari/viewers/Novel/novel_controller.dart';

import 'package:tokuwari/widgets/loading.dart';

class NovelViewer extends StatefulWidget {
  final NovData data;

  const NovelViewer({super.key, required this.data});

  @override
  State createState() => NovelViewerState();
}

class NovelViewerState extends State<NovelViewer> with AutomaticKeepAliveClientMixin {
  late NovelController controller;
  late final novel = getNovel();
  late Map<String, Style> styles;
  //late final height = MediaQuery.sizeOf(context).height;

  Future<void> getNovel() async {
    controller = await NovelController.create(widget.data.path);
    styles = Style.fromCss(controller.cssString, (_, _) {
      print('it failed');
    });
  }

  List<HtmlExtension> get extensions => [
    ImageExtension(
      assetSchema: '',
      builder: (con) {
        final location = Uri.directory(
          p.dirname(controller.chapters[controller.currentChapter].ContentFileName),
        ).resolve(con.attributes['src'] ?? '').path;
        final imageData = controller.epub.images[location]?.Content;
        return Image.memory(imageData!);
      },
    ),
    TagExtension(
      tagsToExtend: {'svg'},
      builder: (con) {
        for (final attr in con.elementChildren.first.attributes.entries) {
          if (attr.key.toString().contains('href')) {
            final location = Uri.directory(
              p.dirname(controller.chapters[controller.currentChapter].ContentFileName),
            ).resolve(attr.value).path;
            final imageData = controller.epub.images[location]?.Content;
            return Image.memory(imageData!);
          }
        }
        return const SizedBox.shrink();
      },
    ),
    TagExtension(
      tagsToExtend: {'uwu'},
      builder: (con) {
        print(con.innerHtml);
        return SizedBox.shrink();
      },
    ),
    TagWrapExtension(
      tagsToWrap: {'fieldset'},
      builder: (child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade700),
            borderRadius: BorderRadius.circular(4),
          ),
          child: child,
        );
      },
    ),
  ];

  String fixSelfClosingScripts(String html) {
    final fixedScripts = html.replaceAllMapped(RegExp(r'<script([^>]*)\s*/>', caseSensitive: false), (match) {
      final attrs = match.group(1)?.trim() ?? '';
      return '<script $attrs></script>';
    });

    final cleaned = fixedScripts.replaceAll(RegExp(r'<span[^>]*\/>'), '');

    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: FutureBuilder(
        future: novel,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                PageView.builder(
                  itemCount: controller.chapters.length,
                  itemBuilder: (context, index) {
                    controller.currentChapter = index;
                    return SafeArea(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1)),
                            child: Html(
                              data: fixSelfClosingScripts(controller.chapters[index].HtmlContent),
                              extensions: extensions,
                              style: styles,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // GestureDetector(
                //   behavior: HitTestBehavior.translucent,
                //   onTap: () => setState(() {
                //     print('yes');
                //     controller.setFontScale(16);
                //   }),
                // ),
                const BackButton(),
              ],
            );
          }
          return const Loading();
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
