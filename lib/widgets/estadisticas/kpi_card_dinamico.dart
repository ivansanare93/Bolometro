import 'package:flutter/material.dart';

class KpiCardDinamico extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool esSubida; // true=subida, false=bajada

  const KpiCardDinamico({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.esSubida = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(width: 6),
                    Icon(
                      esSubida ? Icons.arrow_upward : Icons.arrow_downward,
                      color: esSubida ? Colors.green : Colors.red,
                      size: 18,
                    ),
                  ],
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
