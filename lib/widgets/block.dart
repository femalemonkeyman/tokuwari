import 'package:anicross/providers/info_models.dart';
import 'package:anicross/widgets/image.dart';
import 'package:anicross/widgets/info_page.dart';
import 'package:flutter/material.dart';

class Block extends StatelessWidget {
  final AniData data;

  const Block({
    Key? key,
    required this.data,
  }) : super(key: key);
  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () {
        {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return InfoPage(data: data);
              },
            ),
          );
        }
      },
      child: Column(
        children: [
          Expanded(
            child: AniImage(image: data.image),
          ),
          const Divider(
            height: 5,
          ),
          Container(
            margin: const EdgeInsets.only(left: 15, right: 15),
            child: Text(
              "${data.title}\n",
              maxLines: 2,
              textWidthBasis: TextWidthBasis.longestLine,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  children: [
                    if (data.count != null)
                      Text(
                        "Count: ${data.count}",
                        textScaleFactor: 0.8,
                      ),
                    if (data.score != null)
                      Text(
                        "Score: ${data.score ?? "n/a"}",
                        textScaleFactor: 0.8,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
