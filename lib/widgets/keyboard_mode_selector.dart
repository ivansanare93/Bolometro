import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../l10n/app_localizations.dart';

/// The same keyboard choices in registration and editing, with visible labels.
class KeyboardModeSelector extends StatelessWidget {
  final bool modoVisual;
  final ValueChanged<bool> onChanged;

  const KeyboardModeSelector({
    super.key,
    required this.modoVisual,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    Widget option(bool visual, IconData icon, String label, String tooltip) {
      final selected = modoVisual == visual;
      return Expanded(
        child: Semantics(
          selected: selected,
          child: Tooltip(
            message: tooltip,
            child: TextButton(
              onPressed: () {
                if (!selected) onChanged(visual);
              },
              style: TextButton.styleFrom(
                backgroundColor: selected ? colors.primary : Colors.transparent,
                foregroundColor: selected ? colors.onPrimary : colors.onSurface,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 8),
                  Flexible(child: Text(label, textAlign: TextAlign.center)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            option(
              false,
              Icons.keyboard_rounded,
              l10n.numericKeyboardLabel,
              l10n.switchToClassicKeyboard,
            ),
            const SizedBox(width: 4),
            option(
              true,
              MdiIcons.bowling,
              l10n.pinKeyboardLabel,
              l10n.registerPinsVisually,
            ),
          ],
        ),
      ),
    );
  }
}
