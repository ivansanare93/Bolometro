import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/partida.dart';
import '../l10n/app_localizations.dart';

Future<void> exportarPartidas(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    final box = Hive.box<Partida>('partidas');

    if (box.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noGamesToExport)),
      );
      return;
    }

    final partidas = box.values.toList();
    final jsonList = partidas.map((p) => p.toJson()).toList();
    final jsonString = JsonEncoder.withIndent('  ').convert(jsonList);

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/partidas_exportadas.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], text: l10n.exportShareText);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.exportSuccess)));
    }
  } on HiveError catch (e) {
    debugPrint('Error de Hive al exportar partidas: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.exportErrorAccess),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    debugPrint('Error al exportar partidas: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.exportErrorGeneral),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
