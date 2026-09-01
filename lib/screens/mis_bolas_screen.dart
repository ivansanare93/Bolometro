import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bowling_ball.dart';
import '../repositories/data_repository.dart';
import 'detalle_bola_screen.dart';
import 'editar_bola_screen.dart';

/// Pantalla "Mis Bolas": listado del inventario de bolas de bolos del
/// usuario, con acceso a crear, editar, ver estadísticas y archivar.
class MisBolasScreen extends StatefulWidget {
  const MisBolasScreen({super.key});

  @override
  State<MisBolasScreen> createState() => _MisBolasScreenState();
}

class _MisBolasScreenState extends State<MisBolasScreen> {
  bool _cargando = true;
  String? _error;
  List<BowlingBall> _bolas = [];
  bool _mostrarArchivadas = false;

  @override
  void initState() {
    super.initState();
    _cargarBolas();
  }

  Future<void> _cargarBolas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final repo = Provider.of<DataRepository>(context, listen: false);
      final bolas = await repo.listarTodasLasBolas();
      if (!mounted) return;
      setState(() {
        _bolas = bolas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar tus bolas. Inténtalo de nuevo.';
        _cargando = false;
      });
    }
  }

  List<BowlingBall> get _bolasVisibles => _mostrarArchivadas
      ? _bolas
      : _bolas.where((b) => b.isActive).toList();

  Future<void> _abrirCrearBola() async {
    final creada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditarBolaScreen()),
    );
    if (creada == true) {
      await _cargarBolas();
    }
  }

  Future<void> _abrirDetalle(BowlingBall bola) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalleBolaScreen(ball: bola)),
    );
    await _cargarBolas();
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _bolasVisibles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Bolas'),
        actions: [
          IconButton(
            tooltip: _mostrarArchivadas
                ? 'Ocultar archivadas'
                : 'Mostrar archivadas',
            icon: Icon(
              _mostrarArchivadas ? Icons.visibility_off : Icons.archive_outlined,
            ),
            onPressed: () {
              setState(() => _mostrarArchivadas = !_mostrarArchivadas);
            },
          ),
        ],
      ),
      body: _buildBody(visibles),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirCrearBola,
        tooltip: 'Agregar bola',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(List<BowlingBall> visibles) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _cargarBolas,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (visibles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎳', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text(
                'Todavía no tienes bolas registradas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Agrega tu primera bola para empezar a registrar su uso y ver estadísticas.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _abrirCrearBola,
                icon: const Icon(Icons.add),
                label: const Text('Agregar bola'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarBolas,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: visibles.length,
        itemBuilder: (context, index) {
          final bola = visibles[index];
          return _BolaCard(
            bola: bola,
            onTap: () => _abrirDetalle(bola),
          );
        },
      ),
    );
  }
}

class _BolaCard extends StatelessWidget {
  final BowlingBall bola;
  final VoidCallback onTap;

  const _BolaCard({required this.bola, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: bola.isActive
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
          child: const Text('🎳'),
        ),
        title: Text(
          bola.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          [
            if (bola.brand != null && bola.brand!.trim().isNotEmpty) bola.brand!,
            '${bola.weightLbs.toStringAsFixed(bola.weightLbs.truncateToDouble() == bola.weightLbs ? 0 : 1)} lbs',
            if (!bola.isActive) 'Archivada',
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
