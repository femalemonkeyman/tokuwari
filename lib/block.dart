import 'package:flutter/material.dart';

class Block extends StatelessWidget {
  final String title;
  final Widget image;
  final int? count;
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
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.topLeft,
                            child: BackButton(),
                          ),
                          Row(
                            children: [
                              const Spacer(),
                              Flexible(
                                child: Text(title),
                              ),
                              const Spacer(),
                              Flexible(
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        right: 20, bottom: 40),
                                    child: image,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              description,
                            ),
                          ),
                          mediaList,
                          // AniEpisodes(
                          //   id: id,
                          // ),
                        ],
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
            flex: 55,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: image,
            ),
          ),
          Card(
            margin: const EdgeInsets.only(left: 12, right: 12),
            child: Column(
              children: [
                Text(title),
                Row(
                  children: [
                    const Spacer(
                      flex: 3,
                    ),
                    if (count != null)
                      Flexible(
                        flex: 4,
                        child: Text("Episodes: ${count ?? "n/a"}"),
                      ),
                    const Spacer(
                      flex: 1,
                    ),
                    if (score != null)
                      Flexible(
                        flex: 4,
                        child: Text(
                          "Score: $score",
                        ),
                      ),
                    const Spacer(
                      flex: 1,
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
