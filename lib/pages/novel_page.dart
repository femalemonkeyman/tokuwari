import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:epubx/epubx.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tokuwari/models/novdata.dart';
import 'package:tokuwari/models/repo.dart';
import 'package:tokuwari/widgets/grid.dart';
import 'package:tokuwari/widgets/search_button.dart';
import 'package:permission_handler/permission_handler.dart';

class NovelPage extends StatefulWidget {
  const NovelPage({super.key});

  @override
  State createState() => NovelPageState();
}

class NovelPageState extends State<NovelPage> {
  final box = Repo.i.novdata;
  final List<NovData> novels = [];
  late final Query<NovData> _query;

  @override
  void initState() {
    super.initState();
    _query = box.query(NovData_.type.equals('novel')).order(NovData_.title).build();
    novels.addAll(_query.find());
  }

  @override
  void dispose() {
    _query.close();
    super.dispose();
  }

  @override
  Widget build(context) {
    return novels.isEmpty
        ? ImportNovels(
          state:
              () => setState(() {
                novels.addAll(_query.find());
              }),
        )
        : SafeArea(
          child: CustomScrollView(
            slivers: [
              SearchButton(text: 'Novels', controller: SearchController(), search: () {}),
              SliverToBoxAdapter(
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    TextButton(onPressed: () {}, child: const Text('Add More')),
                    TextButton(
                      onPressed:
                          () => setState(() {
                            box.removeAll();
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
  final box = Repo.i.novdata;
  final VoidCallback state;

  ImportNovels({super.key, required this.state});

  Stream<String> importBooks(BuildContext context) async* {
    if (Platform.isAndroid) await Permission.manageExternalStorage.request();

    final dirPath = await FilePicker.platform.getDirectoryPath(
      lockParentWindow: true,
      dialogTitle: 'Please select a folder containing epubs',
    );
    if (dirPath == null) return;
    final directory = Directory(dirPath);
    if (!directory.existsSync()) return;
    final List<File> epubs = [
      for (final entity in directory.listSync(recursive: true))
        if (entity is File && entity.path.endsWith('.epub')) entity,
    ];
    if (epubs.isEmpty) return;
    final coversDir = Directory(path.join((await getApplicationDocumentsDirectory()).path, '.tokuwari', 'covers'))
      ..createSync(recursive: true);
    final novels = <NovData>[];
    for (final epub in epubs) {
      final book = await compute((file) => EpubReader.openBook(File(file).readAsBytesSync()), epub.path);
      yield book.Title.Title;
      Uint8List getCoverBytes() {
        if (book.cover != null) return Uint8List.fromList(book.cover!.getContentStream());
        final coverItem = book.manifest.Items.firstWhereOrNull(
          (item) =>
              (item.Href.toLowerCase().contains('cover') || item.Id.toLowerCase().contains('cover')) &&
              item.MediaType.contains('image/'),
        );
        if (coverItem == null) return Uint8List(0);
        return Uint8List.fromList(book.Content.Images[coverItem.Href]?.getContentStream() ?? []);
      }

      final imgbits = getCoverBytes();
      if (imgbits.isEmpty) continue;
      final codec = await instantiateImageCodec(imgbits, targetWidth: 306);
      final frame = await codec.getNextFrame();
      final imgBytes = (await frame.image.toByteData(format: ImageByteFormat.png))!;
      final coverPath = path.join(coversDir.path, path.setExtension(path.basename(epub.path), '.png'));
      await File(coverPath).writeAsBytes(imgBytes.buffer.asUint8List());
      novels.add(NovData(type: 'novel', title: book.Title.Title.trim(), image: coverPath, path: epub.path));
    }
    await box.putManyAsync(novels);
    if (context.mounted && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
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
                  builder: (context, snapshot) {
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
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: Text(snapshot.data ?? '', overflow: TextOverflow.ellipsis, maxLines: 1),
                            ),
                            TextButton(
                              onPressed: () async {
                                final coverDir = Directory(
                                  path.join((await getApplicationDocumentsDirectory()).path, '.tokuwari', 'covers'),
                                );
                                if (coverDir.existsSync()) await coverDir.delete(recursive: true);
                                if (dcontext.mounted) dcontext.pop();
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
          state();
        },
        label: const Text("Press me to add novels <3"),
      ),
    );
  }
}
