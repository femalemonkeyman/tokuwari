import 'package:flutter/material.dart';
import 'block.dart';

class Grid extends StatelessWidget {
  final List data;
  final bool keep;
  final int? length;
  const Grid({
    required this.data,
    this.keep = true,
    this.length,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        childAspectRatio: 4 / 6,
        maxCrossAxisExtent: 280,
      ),
      delegate: SliverChildBuilderDelegate(
        childCount: data.length,
        addAutomaticKeepAlives: keep,
        (context, index) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Block(
              data: data[index],
            ),
          );
        },
      ),
    );
  }
}
