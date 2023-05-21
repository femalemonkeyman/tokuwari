import 'package:flutter/material.dart';
import '../models/info_models.dart';
import 'block.dart';

class Grid extends StatefulWidget {
  final List<AniData> data;
  final bool keep;
  final int? length;
  const Grid({
    required this.data,
    this.keep = true,
    this.length,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => GridState();
}

class GridState extends State<Grid> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.keep;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        childAspectRatio: 4 / 6,
        maxCrossAxisExtent: 280,
      ),
      delegate: SliverChildBuilderDelegate(childCount: widget.data.length,
          (context, index) {
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Block(
            data: widget.data[index],
          ),
        );
      }),
    );
  }
}
