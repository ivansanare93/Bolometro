import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bowling_ball.dart';
import '../repositories/data_repository.dart';

/// Abre un bottom sheet para seleccionar una bola activa entre las
/// registradas por el usuario, incluyendo la opción "Sin especificar".
/// Devuelve el [BowlingBall.id] elegido, o `null` al elegir "Sin especificar".
/// Cancelar conserva [seleccionActualId].
Future<BallSelection?> seleccionarBolaConResultado(
  BuildContext context, {
  String? seleccionActualId,
  Set<String> includeBallIds = const {},
}) async {
  final repo = context.read<DataRepository>();
  final owner = repo.arsenalUserId;
  final token = repo.seasonAccountToken;
  final active = await repo.listarBolasActivas();
  final choices = <String, BowlingBall?>{for (final b in active) b.id: b};
  for (final id in {
    ...includeBallIds,
    if (seleccionActualId != null) seleccionActualId,
  }) {
    if (!choices.containsKey(id)) choices[id] = await repo.obtenerBola(id);
  }
  if (!context.mounted ||
      owner != repo.arsenalUserId ||
      token != repo.seasonAccountToken)
    return null;
  final result = await showModalBottomSheet<BallSelection>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      builder: (context, scrollController) => SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '\u00bfCon qu\u00e9 bola jugaste?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text('Sin especificar'),
                    selected: seleccionActualId == null,
                    onTap: () =>
                        Navigator.pop(context, const BallSelection(null)),
                  ),
                  if (choices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Todav\u00eda no tienes bolas activas registradas. Ve a "Mis Bolas" para agregar una.',
                      ),
                    ),
                  for (final e in choices.entries)
                    ListTile(
                      key: ValueKey('ball-choice-${e.key}'),
                      leading: const Icon(Icons.sports_baseball_outlined),
                      title: Text(e.value?.name ?? 'ID: ${e.key}'),
                      subtitle: Text(
                        '${e.value?.brand ?? ''} ${e.value?.weightLbs ?? ''} lb\n${e.key}',
                      ),
                      selected: seleccionActualId == e.key,
                      onTap: () => Navigator.pop(context, BallSelection(e.key)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return owner == repo.arsenalUserId && token == repo.seasonAccountToken
      ? result
      : null;
}

Future<String?> seleccionarBolaBottomSheet(
  BuildContext context, {
  String? seleccionActualId,
}) async {
  final result = await seleccionarBolaConResultado(
    context,
    seleccionActualId: seleccionActualId,
  );
  return result == null ? seleccionActualId : result.id;
}

class BallSelection {
  final String? id;
  const BallSelection(this.id);
}

/// Campo compacto (ListTile) que muestra la bola seleccionada para una
/// partida y permite cambiarla mediante [seleccionarBolaBottomSheet].
class SeleccionarBolaField extends StatefulWidget {
  final String? ballId;
  final String? title;
  final ValueChanged<String?> onChanged;

  const SeleccionarBolaField({
    super.key,
    required this.ballId,
    this.title,
    required this.onChanged,
  });

  @override
  State<SeleccionarBolaField> createState() => _SeleccionarBolaFieldState();
}

class _SeleccionarBolaFieldState extends State<SeleccionarBolaField> {
  late Future<BowlingBall?> _bolaFuture;

  @override
  void initState() {
    super.initState();
    _bolaFuture = _cargarBola();
  }

  @override
  void didUpdateWidget(covariant SeleccionarBolaField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ballId != widget.ballId) {
      _bolaFuture = _cargarBola();
    }
  }

  Future<BowlingBall?> _cargarBola() {
    final ballId = widget.ballId;
    if (ballId == null) return Future.value(null);
    return Provider.of<DataRepository>(
      context,
      listen: false,
    ).obtenerBola(ballId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BowlingBall?>(
      future: _bolaFuture,
      builder: (context, snapshot) {
        final nombreBola =
            snapshot.data?.name ??
            (widget.ballId == null
                ? 'Sin especificar'
                : 'ID: ${widget.ballId}');
        return Card(
          child: ListTile(
            leading: const Text('🎳', style: TextStyle(fontSize: 24)),
            title: Text(widget.title ?? 'Bola utilizada'),
            subtitle: Text(nombreBola),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final seleccionada = await seleccionarBolaBottomSheet(
                context,
                seleccionActualId: widget.ballId,
              );
              if (!context.mounted) return;
              if (seleccionada == widget.ballId) return;
              widget.onChanged(seleccionada);
            },
          ),
        );
      },
    );
  }
}
