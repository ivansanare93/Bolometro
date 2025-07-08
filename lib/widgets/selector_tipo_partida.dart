import 'package:flutter/material.dart';

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
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(labelText: 'Tipo de partida'),
      items: ['Entrenamiento', 'Competición']
          .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
