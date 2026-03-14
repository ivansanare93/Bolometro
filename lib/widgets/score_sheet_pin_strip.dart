import 'package:flutter/material.dart';

/// A small, non-interactive bowling-pin deck visualisation.
///
/// Shows the standard 4-3-2-1 triangle layout:
/// ```
///  7  8  9  10   ← back row
///    4  5  6
///      2  3
///        1       ← head pin
/// ```
/// [pinesCaidos] — list of pin numbers (1-10) that were knocked down,
/// or `null` when no data was recorded for this throw (shown as a
/// ghost/transparent deck).
class PinDeckMini extends StatelessWidget {
  final List<int>? pinesCaidos;

  /// Diameter of each pin circle in logical pixels.
  final double pinSize;

  /// Gap between adjacent pins (both axes) in logical pixels.
  final double pinGap;

  const PinDeckMini({
    super.key,
    required this.pinesCaidos,
    this.pinSize = 8.0,
    this.pinGap = 1.5,
  });

  static const List<List<int>> _pinRows = [
    [7, 8, 9, 10],
    [4, 5, 6],
    [2, 3],
    [1],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final knocked = pinesCaidos;
    final noData = knocked == null;

    // Colours for fallen vs standing pins
    final fallenColor = isDark
        ? theme.colorScheme.primary
        : Colors.red.shade700;
    final standingFill = isDark
        ? const Color(0xFF40454A)
        : Colors.grey.shade200;
    final standingBorder = isDark
        ? Colors.grey.shade600
        : Colors.grey.shade400;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _pinRows.map((row) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: pinGap / 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: row.map((pin) {
              final isFallen = !noData && knocked!.contains(pin);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: pinGap / 2),
                child: Container(
                  width: pinSize,
                  height: pinSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: noData
                        ? Colors.transparent
                        : isFallen
                            ? fallenColor
                            : standingFill,
                    border: Border.all(
                      color: noData
                          ? (isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300)
                          : isFallen
                              ? fallenColor
                              : standingBorder,
                      width: 1.0,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

/// Horizontal "score-sheet" strip showing mini pin decks for every throw
/// across all 10 frames.
///
/// Each frame card shows:
/// - A small header label: F1 … F10
/// - T1 and T2 rows (each with a [PinDeckMini])
/// - An additional T3 row for frame 10 when present
///
/// [frameActivo] optionally highlights the currently active frame with the
/// theme's primary colour border.
class ScoreSheetPinStrip extends StatelessWidget {
  /// Pin data: `pinesPorTiro[frame][throw]` → list of knocked pin numbers,
  /// or `null` if the throw has not yet been recorded.
  final List<List<List<int>?>> pinesPorTiro;

  /// Index (0-based) of the frame to highlight, or `null` for no highlight.
  final int? frameActivo;

  const ScoreSheetPinStrip({
    super.key,
    required this.pinesPorTiro,
    this.frameActivo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF2A2F34) : Colors.white;
    final defaultBorder =
        isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(10, (frameIdx) {
          final isLast = frameIdx == 9;
          final framePines = pinesPorTiro[frameIdx];
          final isActive = frameIdx == frameActivo;

          // Determine the maximum number of throws to show for this frame.
          // For frame 10, show T3 only if it has been recorded (non-null).
          int maxTiros = isLast ? 3 : 2;
          if (isLast && framePines.length >= 3 && framePines[2] == null) {
            maxTiros = 2;
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? theme.colorScheme.primary
                    : defaultBorder,
                width: isActive ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Frame header ──────────────────────────────────────────
                Center(
                  child: Text(
                    'F${frameIdx + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? theme.colorScheme.primary
                          : (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                    ),
                  ),
                ),
                const SizedBox(height: 3),

                // ── Throw rows ────────────────────────────────────────────
                ...List.generate(maxTiros, (tiroIdx) {
                  final pins = tiroIdx < framePines.length
                      ? framePines[tiroIdx]
                      : null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14,
                          child: Text(
                            'T${tiroIdx + 1}',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        PinDeckMini(pinesCaidos: pins),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ),
    );
  }
}
