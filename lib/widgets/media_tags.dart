import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tokuwari/models/anidata.dart';

class MediaTags extends StatelessWidget {
  final AniData data;

  const MediaTags(this.data, {super.key});

  @override
  Widget build(context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(data.tags.length.clamp(0, 15), (index) {
          return ActionChip(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            label: Text(data.tags[index]),
            onPressed:
                () => context.go('/${data.type}?tag=${data.tags[index]}'),
          );
        }),
      ),
    );
  }
}
