import 'dart:async';
import 'dart:io';
import '/models/info_models.dart';
import '/widgets/grid.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class LaterPage extends StatelessWidget {
  final List<AniData> animeData = [];
  final List<AniData> mangaData = [];

  LaterPage({super.key});
  Future<Directory> get dir async {
    return await getApplicationDocumentsDirectory();
  }

  final Isar isar = Isar.getInstance('later')!;
  late final Stream dataChange = isar.aniDatas.watchLazy(fireImmediately: true);

  void updateData() {
    animeData
      ..clear()
      ..addAll(
        isar.aniDatas.filter().typeEqualTo("anime").findAllSync(),
      );
    mangaData
      ..clear()
      ..addAll(
        isar.aniDatas.filter().typeEqualTo("manga").findAllSync(),
      );
  }

  @override
  Widget build(context) {
    return StreamBuilder(
      stream: dataChange,
      builder: (context, snap) {
        updateData();
        return SafeArea(
          child: CustomScrollView(
            slivers: [
              if (animeData.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Divider(),
                      ),
                      Spacer(),
                      Text(
                        'Anime',
                        textScaler: TextScaler.linear(1.2),
                      ),
                      Spacer(),
                      Expanded(
                        flex: 200,
                        child: Divider(),
                      ),
                    ],
                  ),
                ),
              Grid(
                data: animeData,
                keep: false,
                length: animeData.length,
              ),
              if (mangaData.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Divider(),
                      ),
                      Spacer(),
                      Text(
                        'Manga',
                        textScaler: TextScaler.linear(1.2),
                      ),
                      Spacer(),
                      Expanded(
                        flex: 200,
                        child: Divider(),
                      ),
                    ],
                  ),
                ),
              Grid(
                data: mangaData,
                keep: false,
                length: mangaData.length,
              ),
            ],
          ),
        );
      },
    );
  }
}
