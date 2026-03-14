import 'package:flutter/material.dart';

/// Data model for a single pin in the heatmap.
class PinHeatmapData {
  final int pin;
  final int attempts;
  final int converted;
  final double? pct; // null when attempts == 0

  const PinHeatmapData({
    required this.pin,
    required this.attempts,
    required this.converted,
    this.pct,
  });
}

/// Builds per-pin heatmap data from the raw `conversionSparePorPin` map.
///
/// [conversionSparePorPin] maps a comma-separated leave key (e.g. "1,2,3")
/// to `[attempts, converted]`.  For each pin 1..10 we sum up all leaves that
/// contain that pin.
List<PinHeatmapData> buildPerPinHeatmapData(
  Map<String, List<int>> conversionSparePorPin,
) {
  final attemptsPerPin = List<int>.filled(11, 0); // index 1..10
  final convertedPerPin = List<int>.filled(11, 0);

  for (final entry in conversionSparePorPin.entries) {
    final pins = entry.key
        .split(',')
        .map(int.tryParse)
        .whereType<int>()
        .where((p) => p >= 1 && p <= 10);
    final attempts = entry.value[0];
    final converted = entry.value[1];
    for (final p in pins) {
      attemptsPerPin[p] += attempts;
      convertedPerPin[p] += converted;
    }
  }

  return List.generate(10, (i) {
    final pin = i + 1;
    final att = attemptsPerPin[pin];
    final conv = convertedPerPin[pin];
    return PinHeatmapData(
      pin: pin,
      attempts: att,
      converted: conv,
      pct: att > 0 ? conv / att * 100 : null,
    );
  });
}

/// A triangular bowling-pin heatmap.
///
/// Renders 10 pins in the standard bowling arrangement:
///   Row 1 (back):  7  8  9 10
///   Row 2:         4  5  6
///   Row 3:         2  3
///   Row 4 (head):  1
///
/// Each pin is coloured on an orange→green gradient based on its spare
/// conversion percentage.  Pins with no data are shown in grey.
/// Tapping a pin shows a bottom sheet with the full detail.
class PerPinHeatmap extends StatelessWidget {
  final List<PinHeatmapData> data;

  const PerPinHeatmap({super.key, required this.data});

  // Bowling layout: rows from back to head.
  static const _rows = [
    [7, 8, 9, 10],
    [4, 5, 6],
    [2, 3],
    [1],
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Colors.grey[850]! : Colors.grey[100]!;

    // Index data by pin number for O(1) lookup.
    final byPin = {for (final d in data) d.pin: d};

    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            for (final row in _rows) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((pin) {
                  final d = byPin[pin];
                  final pinData = d ??
                      PinHeatmapData(pin: pin, attempts: 0, converted: 0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: _PinCell(data: pinData, isDark: isDark),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            _Legend(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PinCell extends StatelessWidget {
  final PinHeatmapData data;
  final bool isDark;

  const _PinCell({required this.data, required this.isDark});

  Color _pinColor() {
    final pct = data.pct;
    if (pct == null) {
      return isDark ? Colors.grey[700]! : Colors.grey[400]!;
    }
    final t = (pct / 100).clamp(0.0, 1.0);
    // Orange (low) → Green (high)
    return Color.lerp(Colors.deepOrange[600]!, Colors.green[600]!, t)!;
  }

  void _showDetail(BuildContext context) {
    final pct = data.pct;
    final pctText = pct != null ? '${pct.toStringAsFixed(1)}%' : '—';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _pinColor(),
                  child: Text(
                    '${data.pin}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pin ${data.pin}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      pctText,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: _pinColor(),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Intentos', value: '${data.attempts}'),
            _DetailRow(
              label: 'Convertidos',
              value: '${data.converted}',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pct = data.pct;
    final pinColor = _pinColor();
    final labelText = pct != null ? '${pct.toStringAsFixed(0)}%' : '—';
    final semanticsLabel =
        'Pin ${data.pin}: $labelText (${data.converted}/${data.attempts})';

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: pinColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: pinColor.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${data.pin}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                labelText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Legend extends StatelessWidget {
  final bool isDark;

  const _Legend({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const steps = 5;
    final textColor = isDark ? Colors.white70 : Colors.black54;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('0%', style: TextStyle(fontSize: 10, color: textColor)),
        const SizedBox(width: 6),
        Row(
          children: List.generate(steps, (i) {
            final t = i / (steps - 1);
            final color =
                Color.lerp(Colors.deepOrange[600]!, Colors.green[600]!, t)!;
            return Container(
              width: 20,
              height: 10,
              color: color,
            );
          }),
        ),
        const SizedBox(width: 6),
        Text('100%', style: TextStyle(fontSize: 10, color: textColor)),
        const SizedBox(width: 12),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text('Sin datos', style: TextStyle(fontSize: 10, color: textColor)),
      ],
    );
  }
}
