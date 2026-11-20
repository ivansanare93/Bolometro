import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/ball_media_repository.dart';

/// Personal image > explicitly authorised commercial image > owned app asset.
class BallPhoto extends StatefulWidget {
  final String? ownerUid;
  final String? ballId;
  final String? catalogId;
  final String? draftPersonalPath;
  final double size;
  const BallPhoto({
    super.key,
    this.ownerUid,
    this.ballId,
    this.catalogId,
    this.draftPersonalPath,
    this.size = 64,
  });

  @override
  State<BallPhoto> createState() => _BallPhotoState();
}

class _BallPhotoState extends State<BallPhoto> {
  Future<Uint8List?>? _loading;
  Object? _key;

  Widget _generic() => Image.asset(
    'assets/logo_bolometro_min.png',
    width: widget.size,
    height: widget.size,
    fit: BoxFit.contain,
    semanticLabel: 'Imagen genérica de Bolómetro',
    errorBuilder: (_, _, _) => const Icon(Icons.sports_baseball_outlined),
  );

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<BallMediaRepository?>();
    if (repository == null)
      return SizedBox.square(dimension: widget.size, child: _generic());
    final key = (
      repository,
      repository.revision,
      widget.ownerUid,
      widget.ballId,
      widget.catalogId,
      widget.draftPersonalPath,
    );
    if (_key != key) {
      _key = key;
      _loading = repository.resolve(
        uid: widget.ownerUid,
        ballId: widget.ballId,
        catalogId: widget.catalogId,
        draftPersonalPath: widget.draftPersonalPath,
      );
    }
    return SizedBox.square(
      dimension: widget.size,
      child: FutureBuilder<Uint8List?>(
        future: _loading,
        builder: (context, snapshot) {
          // FutureBuilder may retain old data while changing futures. Never show
          // the previous account's picture while the current one is loading.
          if (snapshot.connectionState != ConnectionState.done) {
            return Stack(
              alignment: Alignment.center,
              children: [
                _generic(),
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            );
          }
          final bytes = snapshot.data;
          if (bytes == null || snapshot.hasError) return _generic();
          return Image.memory(
            bytes,
            width: widget.size,
            height: widget.size,
            cacheWidth: (widget.size * MediaQuery.devicePixelRatioOf(context))
                .ceil()
                .clamp(1, 1024),
            fit: BoxFit.contain,
            gaplessPlayback: false,
            semanticLabel: 'Fotografía de la bola',
            errorBuilder: (_, _, _) => _generic(),
          );
        },
      ),
    );
  }
}
