import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/sesion.dart';
import '../utils/app_constants.dart';

class SesionCard extends StatelessWidget {
  final Sesion sesion;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const SesionCard({
    super.key,
    required this.sesion,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: sesion.tipo == AppConstants.tipoCompeticion
              ? Colors.green[200]
              : Colors.blue[200],
          child: Icon(
            sesion.tipo == AppConstants.tipoCompeticion
                ? MdiIcons.trophyVariant
                : MdiIcons.dumbbell,
            color: sesion.tipo == AppConstants.tipoCompeticion
                ? Colors.green[800]
                : Colors.blue[800],
            size: 32,
          ),
        ),
        title: Text(
          '${sesion.tipo}  •  ${sesion.lugar.isEmpty ? "Sin lugar" : sesion.lugar}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '${sesion.fecha.day}/${sesion.fecha.month}/${sesion.fecha.year}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(width: 10),
            Icon(MdiIcons.bowling, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${sesion.partidas.length} partidas',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                tooltip: 'Eliminar',
                onPressed: onDelete,
              )
            : null,
      ),
    );
  }
}
