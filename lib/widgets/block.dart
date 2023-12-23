import '/widgets/image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Block extends StatelessWidget {
  final dynamic data;

  const Block({
    super.key,
    required this.data,
  });

  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () => switch (data.type) {
        'novel' => context.push('/novel/viewer', extra: data),
        _ => context.push('/${data.type}/info', extra: data),
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border.all(strokeAlign: -0.050),
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(0, 0, 0, 0),
                    Color.fromARGB(0, 0, 0, 0),
                    Color.fromARGB(120, 0, 0, 0),
                    Color.fromARGB(255, 0, 0, 0)
                  ],
                ),
              ),
              child: AniImage(image: data.image),
            ),
          ),
          Positioned(
            bottom: 15,
            right: 10,
            left: 10,
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (data.type != 'novel')
            Positioned(
              right: 10,
              top: 10,
              left: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CornerChip(data: "# ${data.count}", bright: true),
                  const Spacer(),
                  CornerChip(data: "★ ${data.score}", bright: false)
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class CornerChip extends StatelessWidget {
  final String data;
  final bool bright;
  static const black = Color.fromARGB(255, 0, 0, 0);
  static const white = Color.fromARGB(255, 255, 255, 255);
  const CornerChip({super.key, required this.data, required this.bright});

  @override
  Widget build(context) {
    return Container(
      padding: const EdgeInsets.only(left: 7, right: 7, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: bright ? white : black, // Ill swear in russian for real lol :D
        borderRadius: const BorderRadius.all(
          Radius.circular(30),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(94, 0, 0, 0),
            spreadRadius: 3,
            blurRadius: 3,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        data,
        style: TextStyle(
          color: bright ? black : white,
        ),
      ),
    );
  }
}
