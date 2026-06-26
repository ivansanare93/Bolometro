import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/sesion.dart';
import '../utils/app_constants.dart';
import '../l10n/app_localizations.dart';

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

  bool get _isCompeticion => sesion.tipo == AppConstants.tipoCompeticion;

  Color get _accentColor =>
      _isCompeticion ? const Color(0xFF2E7D32) : const Color(0xFF0077B6);

  Color get _accentColorLight =>
      _isCompeticion ? const Color(0xFF66BB6A) : const Color(0xFF42A5F5);

  int? get _mejorPuntuacion {
    if (sesion.partidas.isEmpty) return null;
    return sesion.partidas.map((p) => p.total).reduce((a, b) => a > b ? a : b);
  }

  double? get _promedioPuntuacion {
    if (sesion.partidas.isEmpty) return null;
    final suma = sesion.partidas.map((p) => p.total).reduce((a, b) => a + b);
    return suma / sesion.partidas.length;
  }

  String _formatDate(DateTime fecha) {
    final day = fecha.day.toString().padLeft(2, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final year = fecha.year;
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tipoLabel =
        _isCompeticion ? l10n.competition : l10n.training;
    final mejor = _mejorPuntuacion;
    final promedio = _promedioPuntuacion;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Material(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 3,
        shadowColor: _accentColor.withOpacity(0.18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Accent top bar
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accentColor, _accentColorLight],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row: badge + date + delete button
                      Row(
                        children: [
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(isDark ? 0.28 : 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isCompeticion
                                      ? MdiIcons.trophyVariant
                                      : MdiIcons.dumbbell,
                                  size: 14,
                                  color: _accentColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  tipoLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _accentColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Date chip
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 13,
                                  color: cs.onSurface.withOpacity(0.45)),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(sesion.fecha),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withOpacity(0.55),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (onDelete != null) ...[
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 34,
                              height: 34,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red, size: 20),
                                tooltip: l10n.deleteTooltip,
                                onPressed: onDelete,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Location row
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 15,
                              color: cs.onSurface.withOpacity(0.45)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              sesion.lugar.isEmpty
                                  ? l10n.noLocation
                                  : sesion.lugar,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withOpacity(0.85),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_view_month_rounded,
                              size: 15,
                              color: cs.onSurface.withOpacity(0.45)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              sesion.temporadaNormalizada,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface.withOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Stats row
                      Row(
                        children: [
                          _StatChip(
                            icon: MdiIcons.bowling,
                            label: l10n.gamesCount(sesion.partidas.length),
                            color: _accentColor,
                            isDark: isDark,
                          ),
                          if (mejor != null) ...[
                            const SizedBox(width: 8),
                            _StatChip(
                              icon: Icons.emoji_events_rounded,
                              label: '$mejor',
                              color: const Color(0xFFE65100),
                              isDark: isDark,
                            ),
                          ],
                          if (promedio != null) ...[
                            const SizedBox(width: 8),
                            _StatChip(
                              icon: Icons.bar_chart_rounded,
                              label: promedio.toStringAsFixed(0),
                              color:
                                  isDark ? const Color(0xFF90CAF9) : cs.primary,
                              isDark: isDark,
                            ),
                          ],
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withOpacity(0.28),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
