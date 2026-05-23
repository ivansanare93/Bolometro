import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/partida.dart';
import '../models/sesion.dart';
import 'app_constants.dart';

const _shareCardShadowBlur = 28.0;

class SessionShareSummary {
  final List<int> scores;
  final double? average;
  final int? best;
  final int? worst;

  const SessionShareSummary({
    required this.scores,
    required this.average,
    required this.best,
    required this.worst,
  });

  int get gamesCount => scores.length;
}

class GameShareSummary {
  final int strikes;
  final int spares;
  final int misses;

  const GameShareSummary({
    required this.strikes,
    required this.spares,
    required this.misses,
  });
}

SessionShareSummary buildSessionShareSummary(Sesion sesion) {
  final scores = sesion.partidas.map((partida) => partida.total).toList(growable: false);
  if (scores.isEmpty) {
    return const SessionShareSummary(scores: [], average: null, best: null, worst: null);
  }

  final total = scores.reduce((a, b) => a + b);
  return SessionShareSummary(
    scores: scores,
    average: total / scores.length,
    best: scores.reduce(math.max),
    worst: scores.reduce(math.min),
  );
}

GameShareSummary buildGameShareSummary(Partida partida) {
  var strikes = 0;
  var spares = 0;
  var misses = 0;

  // Defensive clamp: imported or legacy data may contain extra frames.
  for (final frame in partida.frames.take(AppConstants.totalFrames)) {
    final firstThrow = frame.isNotEmpty ? frame.first.trim() : '';
    final hasSpare = frame.skip(1).any((throwValue) => throwValue.trim() == AppConstants.simboloSpare);

    if (firstThrow == AppConstants.simboloStrike) {
      strikes++;
    } else if (hasSpare) {
      spares++;
    } else if (frame.any((throwValue) => throwValue.trim().isNotEmpty)) {
      misses++;
    }
  }

  return GameShareSummary(strikes: strikes, spares: spares, misses: misses);
}

String buildSessionShareText({
  required AppLocalizations l10n,
  required Sesion sesion,
  required String localeName,
}) {
  final summary = buildSessionShareSummary(sesion);
  final location = _locationLabel(l10n, sesion.lugar);
  final buffer = StringBuffer()
    ..writeln('🎳 ${l10n.sessionSummaryTitle}')
    ..writeln('${l10n.date}: ${_formatDate(sesion.fecha, localeName)}')
    ..writeln('${l10n.location}: $location')
    ..writeln('${l10n.sessionType}: ${_sessionTypeLabel(l10n, sesion.tipo)}');

  if (summary.scores.isEmpty) {
    buffer
      ..writeln()
      ..writeln(l10n.noGamesRegistered);
  } else {
    buffer.writeln();
    for (var index = 0; index < summary.scores.length; index++) {
      final gameLabel = l10n.gameNumber(index + 1).replaceFirst('🎳 ', '');
      buffer.writeln('- $gameLabel: ${summary.scores[index]}');
    }
    buffer
      ..writeln()
      ..writeln('${l10n.average}: ${_formatAverage(summary.average, localeName)}')
      ..writeln('${l10n.best}: ${summary.best}')
      ..writeln('${l10n.worst}: ${summary.worst}');
  }

  final notes = _cleanNotes(sesion.notas);
  if (notes != null) {
    buffer
      ..writeln()
      ..writeln('${l10n.notes}: $notes');
  }

  buffer
    ..writeln()
    ..write(l10n.generatedWithApp);

  return buffer.toString();
}

String buildGameShareText({
  required AppLocalizations l10n,
  required Sesion sesion,
  required Partida partida,
  required int gameNumber,
  required String localeName,
}) {
  final summary = buildGameShareSummary(partida);
  final date = partida.fecha ?? sesion.fecha;
  final location = _locationLabel(l10n, (partida.lugar ?? sesion.lugar).trim());
  final buffer = StringBuffer()
    ..writeln('🎳 ${l10n.gameSummaryTitle}')
    ..writeln('${l10n.gameNumber(gameNumber)}')
    ..writeln('${l10n.score}: ${partida.total}')
    ..writeln('${l10n.date}: ${_formatDate(date, localeName)}')
    ..writeln('${l10n.location}: $location')
    ..writeln('${l10n.sessionType}: ${_sessionTypeLabel(l10n, sesion.tipo)}')
    ..writeln('${l10n.strikes}: ${summary.strikes}')
    ..writeln('${l10n.spares}: ${summary.spares}')
    ..writeln('${l10n.misses}: ${summary.misses}');

  final notes = _cleanNotes(partida.notas ?? sesion.notas);
  if (notes != null) {
    buffer
      ..writeln()
      ..writeln('${l10n.notes}: $notes');
  }

  buffer
    ..writeln()
    ..write(l10n.generatedWithApp);

  return buffer.toString();
}

Future<void> compartirSesionComoTexto(BuildContext context, Sesion sesion) {
  final l10n = AppLocalizations.of(context)!;
  final localeName = Localizations.localeOf(context).toLanguageTag();
  return _shareText(
    context: context,
    subject: l10n.sessionSummaryTitle,
    text: buildSessionShareText(
      l10n: l10n,
      sesion: sesion,
      localeName: localeName,
    ),
  );
}

Future<void> compartirSesionComoImagen(BuildContext context, Sesion sesion) async {
  final l10n = AppLocalizations.of(context)!;
  final localeName = Localizations.localeOf(context).toLanguageTag();
  final shareText = buildSessionShareText(
    l10n: l10n,
    sesion: sesion,
    localeName: localeName,
  );

  await _shareImage(
    context: context,
    subject: l10n.sessionSummaryTitle,
    description: shareText,
    fileName: 'sesion_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.png',
    pngBytes: await _buildSessionShareImage(
      l10n: l10n,
      sesion: sesion,
      localeName: localeName,
    ),
  );
}

Future<void> compartirPartidaComoTexto(
  BuildContext context,
  Sesion sesion,
  Partida partida,
  int gameNumber,
) {
  final l10n = AppLocalizations.of(context)!;
  final localeName = Localizations.localeOf(context).toLanguageTag();
  return _shareText(
    context: context,
    subject: l10n.gameSummaryTitle,
    text: buildGameShareText(
      l10n: l10n,
      sesion: sesion,
      partida: partida,
      gameNumber: gameNumber,
      localeName: localeName,
    ),
  );
}

Future<void> compartirPartidaComoImagen(
  BuildContext context,
  Sesion sesion,
  Partida partida,
  int gameNumber,
) async {
  final l10n = AppLocalizations.of(context)!;
  final localeName = Localizations.localeOf(context).toLanguageTag();
  final shareText = buildGameShareText(
    l10n: l10n,
    sesion: sesion,
    partida: partida,
    gameNumber: gameNumber,
    localeName: localeName,
  );

  await _shareImage(
    context: context,
    subject: l10n.gameSummaryTitle,
    description: shareText,
    fileName: 'partida_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.png',
    pngBytes: await _buildGameShareImage(
      l10n: l10n,
      sesion: sesion,
      partida: partida,
      gameNumber: gameNumber,
      localeName: localeName,
    ),
  );
}

Future<void> _shareText({
  required BuildContext context,
  required String subject,
  required String text,
}) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    await Share.share(text, subject: subject);
  } catch (error, stackTrace) {
    debugPrint('Error sharing text summary: $error');
    debugPrintStack(stackTrace: stackTrace);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.shareError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _shareImage({
  required BuildContext context,
  required String subject,
  required String description,
  required String fileName,
  required Uint8List pngBytes,
}) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pngBytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: description, subject: subject);
  } catch (error, stackTrace) {
    debugPrint('Error sharing image summary: $error');
    debugPrintStack(stackTrace: stackTrace);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.shareError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<Uint8List> _buildSessionShareImage({
  required AppLocalizations l10n,
  required Sesion sesion,
  required String localeName,
}) {
  final summary = buildSessionShareSummary(sesion);
  return _renderShareCard(
    _ShareCardContent(
      title: l10n.sessionSummaryTitle,
      heroValue: _formatAverage(summary.average, localeName),
      heroLabel: l10n.average,
      accentColor: _accentColorForSession(sesion.tipo),
      chips: [
        '${l10n.totalGames}: ${summary.gamesCount}',
        '${l10n.best}: ${summary.best ?? '-'}',
        '${l10n.worst}: ${summary.worst ?? '-'}',
      ],
      detailLines: [
        _ShareDetailLine(l10n.date, _formatDate(sesion.fecha, localeName)),
        _ShareDetailLine(l10n.location, _locationLabel(l10n, sesion.lugar)),
        _ShareDetailLine(l10n.sessionType, _sessionTypeLabel(l10n, sesion.tipo)),
        if (summary.scores.isNotEmpty) _ShareDetailLine(l10n.score, summary.scores.join(' • ')),
      ],
      notes: _cleanNotes(sesion.notas),
      footer: l10n.generatedWithApp,
    ),
  );
}

Future<Uint8List> _buildGameShareImage({
  required AppLocalizations l10n,
  required Sesion sesion,
  required Partida partida,
  required int gameNumber,
  required String localeName,
}) {
  final summary = buildGameShareSummary(partida);
  final date = partida.fecha ?? sesion.fecha;
  return _renderShareCard(
    _ShareCardContent(
      title: l10n.gameSummaryTitle,
      subtitle: l10n.gameNumber(gameNumber),
      heroValue: partida.total.toString(),
      heroLabel: l10n.score,
      accentColor: _accentColorForSession(sesion.tipo),
      chips: [
        '${l10n.strikes}: ${summary.strikes}',
        '${l10n.spares}: ${summary.spares}',
        '${l10n.misses}: ${summary.misses}',
      ],
      detailLines: [
        _ShareDetailLine(l10n.date, _formatDate(date, localeName)),
        _ShareDetailLine(l10n.location, _locationLabel(l10n, partida.lugar ?? sesion.lugar)),
        _ShareDetailLine(l10n.sessionType, _sessionTypeLabel(l10n, sesion.tipo)),
        _ShareDetailLine(l10n.frames, _framesPreview(partida)),
      ],
      notes: _cleanNotes(partida.notas ?? sesion.notas),
      footer: l10n.generatedWithApp,
    ),
  );
}

Future<Uint8List> _renderShareCard(_ShareCardContent content) async {
  const width = 1080;
  const height = 1350;
  const horizontalPadding = 88.0;
  const cardInset = 54.0;

  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  final canvasRect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  final gradient = ui.Gradient.linear(
    Offset.zero,
    Offset(width.toDouble(), height.toDouble()),
    [content.accentColor, _darken(content.accentColor, 0.18)],
  );

  canvas.drawRect(canvasRect, Paint()..shader = gradient);

  final cardRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(
      cardInset,
      cardInset,
      width - (cardInset * 2),
      height - (cardInset * 2),
    ),
    const Radius.circular(44),
  );

  final cardPath = Path()..addRRect(cardRect);
  canvas.drawShadow(
    cardPath,
    Colors.black.withOpacity(0.22),
    _shareCardShadowBlur,
    true,
  );
  canvas.drawRRect(cardRect, Paint()..color = Colors.white.withOpacity(0.97));

  var top = 110.0;

  top = _drawText(
    canvas: canvas,
    text: content.title,
    left: horizontalPadding,
    top: top,
    maxWidth: width - (horizontalPadding * 2),
    style: const TextStyle(
      fontSize: 56,
      fontWeight: FontWeight.w800,
      color: Color(0xFF162033),
    ),
  );

  if (content.subtitle != null) {
    top += 10;
    top = _drawText(
      canvas: canvas,
      text: content.subtitle!,
      left: horizontalPadding,
      top: top,
      maxWidth: width - (horizontalPadding * 2),
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: content.accentColor,
      ),
    );
  }

  top += 18;
  canvas.drawLine(
    Offset(horizontalPadding, top),
    Offset(width - horizontalPadding, top),
    Paint()
      ..color = const Color(0xFFE3E7EE)
      ..strokeWidth = 3,
  );

  top += 48;
  top = _drawText(
    canvas: canvas,
    text: content.heroValue,
    left: horizontalPadding,
    top: top,
    maxWidth: width - (horizontalPadding * 2),
    style: TextStyle(
      fontSize: 132,
      fontWeight: FontWeight.w900,
      color: content.accentColor,
    ),
    textAlign: TextAlign.center,
    overrideLeft: 0,
  );

  top = _drawText(
    canvas: canvas,
    text: content.heroLabel,
    left: horizontalPadding,
    top: top - 8,
    maxWidth: width - (horizontalPadding * 2),
    style: const TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      color: Color(0xFF5D6A7D),
    ),
    textAlign: TextAlign.center,
    overrideLeft: 0,
  );

  top += 28;
  top = _drawChips(
    canvas: canvas,
    chips: content.chips,
    startTop: top,
    left: horizontalPadding,
    maxWidth: width - (horizontalPadding * 2),
    accentColor: content.accentColor,
  );

  top += 36;
  for (final detailLine in content.detailLines) {
    top = _drawText(
      canvas: canvas,
      text: detailLine.label.toUpperCase(),
      left: horizontalPadding,
      top: top,
      maxWidth: width - (horizontalPadding * 2),
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: content.accentColor,
      ),
    );
    top = _drawText(
      canvas: canvas,
      text: detailLine.value,
      left: horizontalPadding,
      top: top + 4,
      maxWidth: width - (horizontalPadding * 2),
      style: const TextStyle(
        fontSize: 31,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1F2B3E),
        height: 1.25,
      ),
      maxLines: 3,
    );
    top += 18;
  }

  if (content.notes != null) {
    top += 10;
    top = _drawText(
      canvas: canvas,
      text: content.notes!,
      left: horizontalPadding,
      top: top,
      maxWidth: width - (horizontalPadding * 2),
      style: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w400,
        color: Color(0xFF415063),
        height: 1.3,
        fontStyle: FontStyle.italic,
      ),
      maxLines: 5,
    );
  }

  _drawText(
    canvas: canvas,
    text: content.footer,
    left: horizontalPadding,
    top: height - 140,
    maxWidth: width - (horizontalPadding * 2),
    style: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: Color(0xFF718096),
    ),
    textAlign: TextAlign.center,
    overrideLeft: 0,
  );

  final picture = pictureRecorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

double _drawChips({
  required Canvas canvas,
  required List<String> chips,
  required double startTop,
  required double left,
  required double maxWidth,
  required Color accentColor,
}) {
  var currentX = left;
  var currentY = startTop;

  for (final chip in chips) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: chip,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: accentColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final chipWidth = textPainter.width + 40;
    const chipHeight = 48.0;

    if (currentX + chipWidth > left + maxWidth) {
      currentX = left;
      currentY += chipHeight + 14;
    }

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(currentX, currentY, chipWidth, chipHeight),
      const Radius.circular(24),
    );

    canvas.drawRRect(rect, Paint()..color = accentColor.withOpacity(0.12));
    textPainter.paint(canvas, Offset(currentX + 20, currentY + 10));

    currentX += chipWidth + 14;
  }

  return currentY + 62;
}

double _drawText({
  required Canvas canvas,
  required String text,
  required double left,
  required double top,
  required double maxWidth,
  required TextStyle style,
  int? maxLines,
  TextAlign textAlign = TextAlign.left,
  double? overrideLeft,
}) {
  final textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: textAlign,
    maxLines: maxLines,
    ellipsis: maxLines == null ? null : '…',
  )..layout(maxWidth: maxWidth);

  final effectiveLeft = overrideLeft ?? left;
  final paintX = textAlign == TextAlign.center
      ? (heroCenterX - (textPainter.width / 2))
      : effectiveLeft;
  textPainter.paint(canvas, Offset(paintX, top));
  return top + textPainter.height;
}

const heroCenterX = 540.0;

String _formatDate(DateTime date, String localeName) {
  return DateFormat.yMMMMd(localeName).format(date);
}

String _formatAverage(double? value, String localeName) {
  if (value == null) {
    return '-';
  }
  return NumberFormat.decimalPatternDigits(
    locale: localeName,
    decimalDigits: 1,
  ).format(value);
}

String _locationLabel(AppLocalizations l10n, String location) {
  final trimmed = location.trim();
  return trimmed.isEmpty ? l10n.noLocation : trimmed;
}

String _sessionTypeLabel(AppLocalizations l10n, String sessionType) {
  final normalized = sessionType.trim().toLowerCase();
  if (normalized == AppConstants.tipoEntrenamiento.toLowerCase() || normalized == 'training') {
    return l10n.training;
  }
  if (normalized == AppConstants.tipoCompeticion.toLowerCase() || normalized == 'competition') {
    return l10n.competition;
  }
  return sessionType;
}

Color _accentColorForSession(String sessionType) {
  final normalized = sessionType.trim().toLowerCase();
  if (normalized == AppConstants.tipoCompeticion.toLowerCase() || normalized == 'competition') {
    return const Color(0xFFC83F3F);
  }
  return const Color(0xFF2563EB);
}

Color _darken(Color color, double amount) {
  final hslColor = HSLColor.fromColor(color);
  final lightness = (hslColor.lightness - amount).clamp(0.0, 1.0);
  return hslColor.withLightness(lightness).toColor();
}

String _framesPreview(Partida partida) {
  // Defensive clamp: share previews should never render more than 10 frames.
  final frames = partida.frames.take(AppConstants.totalFrames).map((frame) {
    final shots = frame.where((shot) => shot.trim().isNotEmpty).toList();
    return shots.isEmpty ? AppConstants.simboloFallo : shots.join(' ');
  }).toList();
  return frames.join('   |   ');
}

String? _cleanNotes(String? notes) {
  if (notes == null) {
    return null;
  }
  final trimmed = notes.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.length <= 180) {
    return trimmed;
  }
  return '${trimmed.substring(0, 177)}...';
}

class _ShareCardContent {
  final String title;
  final String? subtitle;
  final String heroValue;
  final String heroLabel;
  final Color accentColor;
  final List<String> chips;
  final List<_ShareDetailLine> detailLines;
  final String? notes;
  final String footer;

  const _ShareCardContent({
    required this.title,
    this.subtitle,
    required this.heroValue,
    required this.heroLabel,
    required this.accentColor,
    required this.chips,
    required this.detailLines,
    required this.notes,
    required this.footer,
  });
}

class _ShareDetailLine {
  final String label;
  final String value;

  const _ShareDetailLine(this.label, this.value);
}
