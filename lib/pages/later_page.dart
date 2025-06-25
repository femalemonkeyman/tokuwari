import 'package:flutter/material.dart';
import 'package:tokuwari/models/anidata.dart';
import 'package:tokuwari/models/repo.dart';
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
            TabBar(tabs: [Tab(text: 'Anime'), Tab(text: 'Manga'), Tab(text: 'Recent')]),
            Expanded(child: TabBarView(children: [LaterGrid('anime'), LaterGrid('manga'), Placeholder()])),
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

class LaterGridState extends State<LaterGrid> with AutomaticKeepAliveClientMixin {
  final box = Repo.i.anidata;
  late final Stream<List<AniData>> _queryStream;

  @override
  void initState() {
    super.initState();
    _queryStream = box.query(AniData_.type.equals(widget.type)).order(AniData_.id).assign();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return CustomScrollView(
      slivers: [
        StreamBuilder<List<AniData>>(
          stream: _queryStream,
          builder: (context, snapshot) {
            final data = (snapshot.data ?? []).reversed.toList();
            if (data.isNotEmpty) {
              return Grid(data: data, keep: false, length: data.length);
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
