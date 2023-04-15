import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AniImage extends StatelessWidget {
  final String image;

  const AniImage({required this.image, super.key});

  @override
  Widget build(context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15.0),
      child: image.startsWith("/")
          ? Image.file(
              File(image),
              fit: BoxFit.cover,
            )
          : CachedNetworkImage(
              imageUrl: image,
              fit: BoxFit.cover,
            ),
    );
  }
}