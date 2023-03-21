import 'package:flutter/material.dart';
import '../providers/info_models.dart';
import 'block.dart';

class Grid extends StatefulWidget {
  final List<AniData> data;
  final Function paginate;
  const Grid({
    required this.data,
    required this.paginate,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => GridState();
}

class GridState extends State<Grid> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SliverGrid(
      //primary: false,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 4 / 6,
        maxCrossAxisExtent: 270,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index <= widget.data.length - 5) {
            return Block(
              data: widget.data[index],
            );
          } else {
            widget.paginate();
          }
          return null;
        },
      ),
    );
  }
}
