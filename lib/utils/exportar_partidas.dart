import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/partida.dart';

Future<void> exportarPartidas(BuildContext context) async {
  try {
    final box = Hive.box<Partida>('partidas');

    if (box.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay partidas para exportar')),
      );
      return;
    }

    final partidas = box.values.toList();
    final jsonList = partidas.map((p) => p.toJson()).toList();
    final jsonString = JsonEncoder.withIndent('  ').convert(jsonList);

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/partidas_exportadas.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], text: 'Mis partidas de bolos');

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Exportación completada')));
    }
  } on HiveError catch (e) {
    debugPrint('Error de Hive al exportar partidas: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al acceder a las partidas. Intenta nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    debugPrint('Error al exportar partidas: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al exportar partidas. Intenta nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
