import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AniImage extends StatelessWidget {
  final String image;

  const AniImage({required this.image, super.key});

  @override
  Widget build(context) {
    //final height = MediaQuery.of(context).size.height.clamp(0, 170);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: image.startsWith("/")
          ? Image.file(
              File(image),
              fit: BoxFit.cover,
            )
          : CachedNetworkImage(
              imageUrl: image,
              fit: BoxFit.cover,
              //height: height.toDouble(),
            ),
    );
  }
}
