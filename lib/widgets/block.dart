import 'package:anicross/models/info_models.dart';
import 'package:anicross/novel/novel_reader.dart';
import 'package:anicross/widgets/image.dart';
import 'package:anicross/info_page.dart';
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
                if (data.type == "novel") {
                  return NovelReader(
                    data: data,
                  );
                }
                return InfoPage(
                  data: data,
                );
              },
            ),
          );
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border.all(strokeAlign: -0.050),
                borderRadius: BorderRadius.circular(15),
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
          if (data.score != null)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  color: Colors.black, //Yes
                  borderRadius: BorderRadius.all(
                    Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(94, 0, 0, 0),
                      spreadRadius: 3,
                      blurRadius: 3,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  "★ ${data.score ?? "n/a"}",
                ),
              ),
            ),
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: const BoxDecoration(
                color: Colors.white, // Ill swear in russian for real lol :D
                borderRadius: BorderRadius.all(
                  Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(94, 0, 0, 0),
                    spreadRadius: 3,
                    blurRadius: 3,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                "# ${data.count ?? "n/a"}",
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
