import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../l10n/app_localizations.dart';

class SelectorTipoPartida extends StatelessWidget {
  final String value;
  final void Function(String?) onChanged;

  const SelectorTipoPartida({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: l10n.sessionType),
      items: AppConstants.tiposSesion
          .map((tipo) => DropdownMenuItem(value: tipo, child: Text(_translateTipo(tipo, l10n))))
          .toList(),
      onChanged: onChanged,
    );
  }

  String _translateTipo(String tipo, AppLocalizations l10n) {
    if (tipo == AppConstants.tipoEntrenamiento) return l10n.training;
    if (tipo == AppConstants.tipoCompeticion) return l10n.competition;
    return tipo;
  }
}
