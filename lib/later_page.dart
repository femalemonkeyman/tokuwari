import 'dart:async';
import 'dart:io';
import 'package:anicross/models/info_models.dart';
import 'package:anicross/widgets/grid.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class LaterPage extends StatefulWidget {
  const LaterPage({super.key});

  @override
  State createState() => LaterPageState();
}

class LaterPageState extends State<LaterPage> {
  List<AniData> animeData = [];
  List<AniData> mangaData = [];
  Future<Directory> get dir async {
    return await getApplicationDocumentsDirectory();
  }

  final Isar isar = Isar.getInstance('later')!;
  late final dataChange = isar.aniDatas.watchLazy(fireImmediately: true);

  @override
  void initState() {
    super.initState();
  }

  void updateData() {
    animeData = isar.aniDatas.filter().typeEqualTo("anime").findAllSync();
    mangaData = isar.aniDatas.filter().typeEqualTo("manga").findAllSync();
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
              Grid(
                data: animeData,
                keep: false,
                length: animeData.length,
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
