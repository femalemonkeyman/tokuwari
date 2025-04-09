import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:epubx/epubx.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tokuwari/models/novdata.dart';
import 'package:tokuwari/widgets/grid.dart';
import 'package:tokuwari/widgets/search_button.dart';
import 'package:permission_handler/permission_handler.dart';

class NovelPage extends StatefulWidget {
  const NovelPage({super.key});

  @override
  State createState() => NovelPageState();
}

class NovelPageState extends State<NovelPage> {
  final Isar isar = Isar.get(schemas: [NovDataSchema], name: 'tokudb');
  final List<NovData> novels = [];

  @override
  void initState() {
    novels.addAll(
      isar.novDatas.where().typeEqualTo('novel').sortByTitle().findAll(),
    );
    super.initState();
  }

  @override
  Widget build(context) {
    return novels.isEmpty
        ? ImportNovels(
          state:
              () => setState(() {
                novels.addAll(
                  isar.novDatas
                      .where()
                      .typeEqualTo('novel')
                      .sortByTitle()
                      .findAll(),
                );
              }),
        )
        : SafeArea(
          child: CustomScrollView(
            slivers: [
              SearchButton(
                text: 'Novels',
                controller: SearchController(),
                search: () {},
              ),
              SliverToBoxAdapter(
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    TextButton(onPressed: () {}, child: const Text('Add More')),
                    TextButton(
                      onPressed:
                          () => setState(() {
                            isar.write((isar) => isar.novDatas.clear());
                            novels.clear();
                          }),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              Grid(data: novels),
            ],
          ),
        );
  }
}

class ImportNovels extends StatelessWidget {
  final Isar isar = Isar.get(schemas: [NovDataSchema], name: 'tokudb');
  final VoidCallback state;

  ImportNovels({super.key, required this.state});

  Stream<String> importBooks(final BuildContext context) async* {
    if (Platform.isAndroid) {
      await Permission.manageExternalStorage.request();
    }
    final directory = Directory(
      await FilePicker.platform.getDirectoryPath(
            lockParentWindow: true,
            dialogTitle: 'Please select a folder containing epubs',
          ) ??
          '',
    );
    if (directory.existsSync()) {
      final List<File> epubs = [
        for (final entity in directory.listSync(recursive: true))
          if (entity is File && entity.path.endsWith('.epub')) entity,
      ];
      if (epubs.isNotEmpty) {
        final covers = path.join(
          (await getApplicationDocumentsDirectory()).path,
          '.tokuwari',
          'covers/',
        );
        final novels = <NovData>[];
        for (File epub in epubs) {
          final bookref = await compute((epub) async {
            return await EpubReader.openBook(epub.readAsBytesSync());
          }, epub);
          yield bookref.Title.Title;
          final imgbits = Uint8List.fromList(
            bookref.cover?.getContentStream() ??
                bookref
                    .Content
                    .Images[(bookref.manifest.Items
                        .firstWhereOrNull(
                          (item) =>
                              (item.Href.toLowerCase().contains('cover') ||
                                  item.Id.toLowerCase().contains('cover')) &&
                              item.MediaType.contains('image/'),
                        )
                        ?.Href)]
                    ?.getContentStream() ??
                [],
          );
          final codec = await instantiateImageCodec(imgbits, targetWidth: 306);
          final resizedImage = (await codec.getNextFrame()).image;
          final img = await resizedImage.toByteData(
            format: ImageByteFormat.png,
          );
          final cover =
              (Directory(covers)..createSync()).path +
              path.setExtension(path.basename(epub.path), '.png');
          File(cover).writeAsBytes(img!.buffer.asUint8List());
          novels.add(
            NovData(
              type: 'novel',
              title: bookref.Title.Title.trim(),
              image: cover,
              path: epub.path,
            ),
          );
        }
        isar.write((isar) => isar.novDatas.putAll(novels));
      }
    }
    if (context.mounted && context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(context) {
    return Center(
      child: ActionChip(
        onPressed: () async {
          await showAdaptiveDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (dcontext) => StreamBuilder<String>(
                  initialData: '...',
                  stream: importBooks(dcontext),
                  builder: (context, snap) {
                    final height = MediaQuery.of(context).size.height / 4;
                    return Dialog(
                      child: SizedBox.square(
                        dimension: height,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Text('Importing:'),
                            Padding(
                              padding: const EdgeInsets.only(left: 5, right: 5),
                              child: Text(
                                snap.data ?? '',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final dir = Directory(
                                  path.join(
                                    (await getApplicationDocumentsDirectory())
                                        .path,
                                    '.tokuwari',
                                    'covers/',
                                  ),
                                );
                                if (dir.existsSync()) {
                                  dir.delete();
                                }
                                if (dcontext.mounted) {
                                  dcontext.pop();
                                }
                              },
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          );
          state.call();
        },
        label: const Text("Press me to add novels <3"),
      ),
    );
  }
}
