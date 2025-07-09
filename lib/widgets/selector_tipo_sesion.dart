import 'package:flutter/material.dart';

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
      items: [
        'Todos',
        'Entrenamiento',
        'Competición',
      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      borderRadius: BorderRadius.circular(14),
    );
  }
}
