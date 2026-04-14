import 'package:flutter/material.dart';

/// A small info icon that shows a [Tooltip] with contextual help text.
///
/// Usage:
/// ```dart
/// Row(
///   children: [
///     Text('Moving Average'),
///     const SizedBox(width: 4),
///     InfoTooltipIcon(message: 'Calculated over the last 5 games.'),
///   ],
/// )
/// ```
class InfoTooltipIcon extends StatelessWidget {
  const InfoTooltipIcon({
    super.key,
    required this.message,
    this.size = 16.0,
    this.color,
  });

  final String message;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Icon(
        Icons.info_outline_rounded,
        size: size,
        color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
      ),
    );
  }
}
