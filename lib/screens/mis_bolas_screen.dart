import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bowling_ball.dart';
import '../repositories/data_repository.dart';
import 'detalle_bola_screen.dart';
import 'editar_bola_screen.dart';
import '../widgets/arsenal_history_button.dart';

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
  String? _visibleUid;
  bool _boundAccount = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = Provider.of<DataRepository>(context).arsenalUserId;
    if (!_boundAccount || uid != _visibleUid) {
      _boundAccount = true;
      _visibleUid = uid;
      _bolas = [];
      _cargarBolas();
    }
  }

  Future<void> _cargarBolas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final repo = Provider.of<DataRepository>(context, listen: false);
      final uid = repo.arsenalUserId;
      final bolas = await repo.listarTodasLasBolas();
      if (!mounted || uid != repo.arsenalUserId) return;
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

  Future<void> _backup() async {
    final repo = context.read<DataRepository>();
    try {
      await repo.sincronizarArsenal();
      if (mounted) await _cargarBolas();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No se pudo confirmar el respaldo. Conservamos tus datos en este dispositivo.'),
      ));
    }
  }

  Future<void> _importGuest() async {
    final repo = context.read<DataRepository>();
    final uid = repo.arsenalUserId;
    try {
      final count = await repo.bolasInvitadasDisponibles();
      if (!mounted || uid != repo.arsenalUserId) return;
      final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: const Text('Importar arsenal de invitado'),
        content: Text('$count bolas disponibles. Se vincularán a la cuenta actual ($uid), junto con sus mantenimientos y partidas relacionadas. La copia original se conserva y no se importará a otra cuenta.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Importar'))],
      ));
      if (confirmed != true || uid != repo.arsenalUserId) return;
      await repo.importarArsenalInvitado();
      if (mounted) await _cargarBolas();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _reviewConflict(String key) async {
    final repo = context.read<DataRepository>();
    final service = repo.arsenalSync;
    if (service == null) return;
    final conflict = service.conflict(key);
    final keepLocal = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Dos versiones conservadas'),
      content: SingleChildScrollView(child: SelectableText(
        'Este dispositivo:\n${describeArsenalPayload((conflict['legacyVariant'] ?? conflict['payload']) as Map?)}\n\nCuenta:\n${describeArsenalPayload(conflict['remotePayload'] as Map?)}\n\nLas versiones enviadas se conservan en el historial del respaldo. Elige cuál quieres usar.' )),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Más tarde')),
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Usar cuenta')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Usar dispositivo'))],
    ));
    if (keepLocal == null || !identical(service, repo.arsenalSync)) return;
    try {
      await service.resolve(key, keepLocal: keepLocal);
      await _backup();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
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
    final repo = context.watch<DataRepository>();
    final service = repo.arsenalSync;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Bolas'),
        actions: [
          if (repo.arsenalUserId != null) ...[
            IconButton(tooltip: 'Respaldar y recuperar arsenal',
              onPressed: !repo.arsenalBackupEnabled || service == null || service.isSyncing ? null : _backup,
              icon: const Icon(Icons.cloud_sync)),
            IconButton(tooltip: 'Importar arsenal de invitado',
              onPressed: service == null ? null : _importGuest,
              icon: const Icon(Icons.move_to_inbox_outlined)),
          ],
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
      body: Column(children: [
        ListTile(dense: true, leading: Icon(service?.error != null ? Icons.cloud_off : Icons.info_outline),
          title: Text(repo.arsenalUserId == null
            ? 'Solo en este dispositivo. Inicia sesión e importa el arsenal para respaldarlo.'
            : !repo.arsenalBackupEnabled ? 'Conservado en este dispositivo. Respaldo remoto pendiente de activación.'
            : service?.isSyncing == true ? 'Comprobando respaldo…'
            : service?.error != null ? 'Respaldo pendiente: no se pudo confirmar con tu cuenta.'
            : service == null ? 'Preparando cuenta…'
            : service.conflicts.isNotEmpty ? 'Hay versiones diferentes que necesitan revisión.'
            : service.pendingCount > 0 ? '${service.pendingCount} cambios pendientes de respaldo.'
            : service.hasConfirmedBackup ? 'Respaldo confirmado en la última sincronización.'
            : 'Aún no hay respaldo confirmado.'),
          subtitle: const Text('No reinstales ni borres los datos mientras haya cambios pendientes.'),
        ),
        if (service != null)
          for (final key in service.conflicts)
            TextButton(onPressed: () => _reviewConflict(key), child: Text('Revisar $key')),
        Expanded(child: _buildBody(visibles)),
      ]),
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
