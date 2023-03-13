import 'package:anicross/providers/info_models.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';

import 'image.dart';

class InfoPage extends StatelessWidget {
  final AniData data;

  const InfoPage({required this.data, super.key});

  @override
  Widget build(context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
              padding: const EdgeInsets.only(
                right: 20,
                left: 20,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Align(
                        alignment: Alignment.topLeft,
                        child: BackButton(),
                      ),
                      const Divider(
                        height: 15,
                      ),
                      Flexible(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              flex: 2,
                              child: AniImage(
                                image: data.image,
                              ),
                            ),
                            const VerticalDivider(
                              width: 20,
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                data.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(
                        height: 30,
                      ),
                      ExpandableText(
                        data.description,
                        expandText: "More",
                        collapseText: "Less",
                        maxLines: 8,
                      ),
                      const Divider(
                        height: 30,
                      ),
                      //mediaList,
                    ],
                  );
                },
              )),
        ),
      ),
    );
  }
}
