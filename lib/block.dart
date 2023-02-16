import 'package:flutter/material.dart';

class Block extends StatelessWidget {
  final String title;
  final Widget image;
  final String? count;
  final int? score;
  final String description;
  final Widget mediaList;

  const Block({
    Key? key,
    required this.title,
    required this.image,
    required this.description,
    this.count,
    this.score,
    this.mediaList = const SizedBox.shrink(),
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
                return Scaffold(
                  body: SingleChildScrollView(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20, left: 20),
                        child: Column(
                          children: [
                            const Align(
                              alignment: Alignment.topLeft,
                              child: BackButton(),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(title),
                                ),
                                Flexible(
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: image,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(
                              height: 30,
                            ),
                            Text(
                              description,
                            ),
                            const Divider(
                              height: 30,
                            ),
                            mediaList,
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }
      },
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: image,
            ),
          ),
          Card(
            margin: const EdgeInsets.only(left: 12, right: 12),
            child: Column(
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        children: [
                          if (count != null)
                            Text(
                              "Count: ${count ?? "n/a"}",
                              textScaleFactor: 0.8,
                            ),
                          if (score != null)
                            Text(
                              "Score: $score",
                              textScaleFactor: 0.8,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
