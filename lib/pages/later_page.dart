import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:tokuwari_models/info_models.dart';
import '/widgets/grid.dart';

class LaterPage extends StatelessWidget {
  final Isar isar = Isar.get(schemas: [AniDataSchema], name: 'tokudb');

  LaterPage({super.key});

  @override
  Widget build(context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          StreamBuilder<List<AniData>>(
            initialData: isar.aniDatas.where().typeEqualTo('anime').findAll(),
            stream: isar.aniDatas.where().typeEqualTo('anime').watch(),
            builder: (context, snap) {
              if (snap.hasData && snap.data!.isNotEmpty) {
                return MultiSliver(
                  children: [
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
                      data: snap.data!.reversed.toList(),
                      keep: false,
                      length: snap.data!.length,
                    ),
                  ],
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
          StreamBuilder<List<AniData>>(
            initialData: isar.aniDatas.where().typeEqualTo('manga').findAll(),
            stream: isar.aniDatas.where().typeEqualTo('manga').watch(),
            builder: (context, snap) {
              if (snap.hasData && snap.data!.isNotEmpty) {
                return MultiSliver(
                  children: [
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
                      data: snap.data!,
                      keep: false,
                      length: snap.data!.length,
                    ),
                  ],
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
        ],
      ),
    );
  }
}
