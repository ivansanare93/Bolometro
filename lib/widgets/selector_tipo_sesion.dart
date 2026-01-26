import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class SelectorTipoSesion extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const SelectorTipoSesion({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(labelText: 'Filtrar por tipo'),
      items: AppConstants.tiposSesionConTodos
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      borderRadius: BorderRadius.circular(14),
    );
  }
}
