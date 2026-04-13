import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';
import '../l10n/app_localizations.dart';

/// Diálogo que informa al usuario de que hay una nueva versión disponible.
///
/// Si [updateInfo.forceUpdate] es `true`, el botón "Más tarde" queda
/// deshabilitado y el usuario no puede cerrar el diálogo.
class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  /// Muestra el diálogo. Si [barrierDismissible] es `false` cuando la
  /// actualización es forzada.
  static Future<void> show(BuildContext context, UpdateInfo updateInfo) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (_) => UpdateDialog(updateInfo: updateInfo),
    );
  }

  Future<void> _openStore() async {
    final uri = Uri.tryParse(updateInfo.updateUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !updateInfo.forceUpdate,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.system_update_alt, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.updateAvailable,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.updateVersion}: ${updateInfo.latestVersion}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
            if (updateInfo.changelog.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.updateChangelog,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                updateInfo.changelog,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          if (!updateInfo.forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.updateLater),
            ),
          FilledButton.icon(
            onPressed: _openStore,
            icon: const Icon(Icons.download),
            label: Text(l10n.updateNow),
          ),
        ],
      ),
    );
  }
}
