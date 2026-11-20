import 'package:flutter/material.dart';
import '../models/catalog_ball.dart';
import 'ball_photo.dart';

/// Only the release-reviewed registry authorises commercial pictures.
class CatalogBallImage extends StatelessWidget {
  final CatalogPhoto? photo;
  final String? catalogId;
  final double size;
  const CatalogBallImage({
    super.key,
    this.photo,
    this.catalogId,
    this.size = 64,
  });
  @override
  Widget build(BuildContext context) =>
      BallPhoto(catalogId: catalogId, size: size);
}
