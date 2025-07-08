import 'package:flutter/material.dart';

class NotasField extends StatelessWidget {
  final String? initialValue;
  final void Function(String) onChanged;
  final VoidCallback? onTap;
  final void Function(bool)? onFocusChange;

  const NotasField({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.onTap,
    this.onFocusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: onFocusChange,
      child: TextFormField(
        initialValue: initialValue,
        decoration: const InputDecoration(
          labelText: 'Notas (opcional)',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
        onChanged: onChanged,
        onTap: onTap,
      ),
    );
  }
}
