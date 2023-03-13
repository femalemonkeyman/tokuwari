import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';
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
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: GridView.builder(
        itemCount: widget.data.length,
        shrinkWrap: true,
        primary: false,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          mainAxisSpacing: 10,
          crossAxisSpacing: 0,
          childAspectRatio: 0.69,
          crossAxisCount:
              Platform.isAndroid || Platform.isIOS && !kIsWeb ? 2 : 4,
        ),
        itemBuilder: (context, index) {
          return Block(
            data: widget.data[index],
          );
        },
      ),
    );
  }
}
