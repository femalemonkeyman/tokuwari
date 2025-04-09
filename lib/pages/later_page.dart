import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:tokuwari/models/anidata.dart';
import '/widgets/grid.dart';

class LaterPage extends StatelessWidget {
  const LaterPage({super.key});

  @override
  Widget build(context) {
    return const SafeArea(
      child: DefaultTabController(
        length: 3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //SearchButton(text: 'Favourites', controller: TextEditingController(), search: () {}),
            TabBar(
              tabs: [
                Tab(text: 'Anime'),
                Tab(text: 'Manga'),
                Tab(text: 'Recent'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  LaterGrid('anime'),
                  LaterGrid('manga'),
                  Placeholder(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LaterGrid extends StatefulWidget {
  final String type;
  const LaterGrid(this.type, {super.key});

  @override
  State createState() => LaterGridState();
}

class LaterGridState extends State<LaterGrid>
    with AutomaticKeepAliveClientMixin {
  final Isar isar = Isar.get(schemas: [AniDataSchema], name: 'tokudb');
  late final stream = isar.aniDatas
      .where()
      .typeEqualTo(widget.type)
      .watch(fireImmediately: true);

  @override
  Widget build(context) {
    super.build(context);
    return CustomScrollView(
      slivers: [
        StreamBuilder<List<AniData>>(
          initialData: isar.aniDatas.where().typeEqualTo(widget.type).findAll(),
          stream: stream,
          builder: (context, snap) {
            if (snap.hasData && snap.data!.isNotEmpty) {
              final data = snap.data!.reversed.toList();
              return Grid(data: data, keep: false, length: snap.data!.length);
            }
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
