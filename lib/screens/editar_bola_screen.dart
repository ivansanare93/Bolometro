import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/bowling_ball.dart';
import '../repositories/data_repository.dart';
import '../services/analytics_service.dart';

/// Formulario para crear o editar una bola de bolos.
class EditarBolaScreen extends StatefulWidget {
  final BowlingBall? ball;

  const EditarBolaScreen({super.key, this.ball});

  bool get isEditing => ball != null;

  @override
  State<EditarBolaScreen> createState() => _EditarBolaScreenState();
}

class _EditarBolaScreenState extends State<EditarBolaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _marcaController;
  late final TextEditingController _pesoController;
  late final TextEditingController _coverstockController;
  late final TextEditingController _acabadoController;
  late final TextEditingController _notasController;
  DateTime? _fechaCompra;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final bola = widget.ball;
    _nombreController = TextEditingController(text: bola?.name ?? '');
    _marcaController = TextEditingController(text: bola?.brand ?? '');
    _pesoController = TextEditingController(
      text: bola != null ? _formatPeso(bola.weightLbs) : '',
    );
    _coverstockController = TextEditingController(text: bola?.coverstock ?? '');
    _acabadoController = TextEditingController(text: bola?.finish ?? '');
    _notasController = TextEditingController(text: bola?.notes ?? '');
    _fechaCompra = bola?.purchaseDate;
  }

  String _formatPeso(double peso) {
    return peso.truncateToDouble() == peso
        ? peso.toStringAsFixed(0)
        : peso.toString();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _marcaController.dispose();
    _pesoController.dispose();
    _coverstockController.dispose();
    _acabadoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaCompra() async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaCompra ?? ahora,
      firstDate: DateTime(1990),
      lastDate: ahora,
    );
    if (fecha != null) {
      setState(() => _fechaCompra = fecha);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    final repo = Provider.of<DataRepository>(context, listen: false);
    final analytics = Provider.of<AnalyticsService>(context, listen: false);

    final peso = double.parse(_pesoController.text.trim().replaceAll(',', '.'));
    final nombre = _nombreController.text.trim();
    final marca = _marcaController.text.trim();
    final coverstock = _coverstockController.text.trim();
    final acabado = _acabadoController.text.trim();
    final notas = _notasController.text.trim();

    try {
      if (widget.isEditing) {
        final actualizada = widget.ball!.copyWith(
          name: nombre,
          brand: marca.isEmpty ? null : marca,
          weightLbs: peso,
          coverstock: coverstock.isEmpty ? null : coverstock,
          finish: acabado.isEmpty ? null : acabado,
          purchaseDate: _fechaCompra,
          notes: notas.isEmpty ? null : notas,
        );
        await repo.actualizarBola(actualizada);
      } else {
        final nueva = BowlingBall(
          name: nombre,
          brand: marca.isEmpty ? null : marca,
          weightLbs: peso,
          coverstock: coverstock.isEmpty ? null : coverstock,
          finish: acabado.isEmpty ? null : acabado,
          purchaseDate: _fechaCompra,
          notes: notas.isEmpty ? null : notas,
        );
        await repo.crearBola(nueva);
        await logBallCreatedSafely(analytics);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la bola. Inténtalo de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Bola' : 'Agregar Bola'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                hintText: 'p. ej. Storm Phaze II',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _marcaController,
              decoration: const InputDecoration(labelText: 'Marca'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pesoController,
              decoration: const InputDecoration(
                labelText: 'Peso (lbs) *',
                hintText: 'p. ej. 15',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final texto = value?.trim().replaceAll(',', '.') ?? '';
                if (texto.isEmpty) return 'El peso es obligatorio';
                final peso = double.tryParse(texto);
                if (peso == null) return 'Introduce un peso válido';
                if (peso <= 0 || peso > 20) {
                  return 'El peso debe estar entre 1 y 20 lbs';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _coverstockController,
              decoration: const InputDecoration(labelText: 'Coverstock'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _acabadoController,
              decoration: const InputDecoration(labelText: 'Acabado (finish)'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha de compra'),
              subtitle: Text(
                _fechaCompra != null
                    ? DateFormat('dd/MM/yyyy').format(_fechaCompra!)
                    : 'Sin especificar',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _seleccionarFechaCompra,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notasController,
              decoration: const InputDecoration(labelText: 'Notas'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
