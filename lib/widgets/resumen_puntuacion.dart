import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class ResumenPuntuacion extends StatelessWidget {
  final int puntuacionActual;
  final int puntuacionMaxima;
  final bool buenaRacha;

  const ResumenPuntuacion({
    super.key,
    required this.puntuacionActual,
    required this.puntuacionMaxima,
    required this.buenaRacha,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A2740), const Color(0xFF0E1828)]
              : [const Color(0xFF0077B6), const Color(0xFF00B4D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark
                    ? const Color(0xFF0096C7)
                    : const Color(0xFF0077B6))
                .withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          // Current score
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puntuación',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$puntuacionActual',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 52,
            color: Colors.white.withOpacity(0.25),
          ),
          const SizedBox(width: 16),
          // Max possible
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Máximo posible',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$puntuacionMaxima',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          if (buenaRacha) ...[
            const SizedBox(width: 8),
            Column(
              children: [
                Icon(Icons.whatshot_rounded,
                    color: Colors.orange.shade300, size: 30),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.onStreak,
                  style: TextStyle(
                    color: Colors.orange.shade300,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
