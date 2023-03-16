import 'package:flutter/material.dart';
import '../providers/info_models.dart';
import 'block.dart';

class Grid extends StatefulWidget {
  final List<AniData> data;
  const Grid({
    required this.data,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: GridView.builder(
            itemCount: widget.data.length,
            shrinkWrap: true,
            primary: false,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 4 / 6,
              maxCrossAxisExtent: 270,
            ),
            itemBuilder: (context, index) {
              return Block(
                data: widget.data[index],
              );
            },
          ),
        );
      },
    );
  }
}
