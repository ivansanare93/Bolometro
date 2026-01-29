import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/partida.dart';
import '../models/sesion.dart';
import 'registro_sesion.dart';
import 'editar_partida.dart';
import '../widgets/lista_partidas.dart';
import '../widgets/selector_tipo_partida.dart';
import '../utils/app_constants.dart';
import '../repositories/data_repository.dart';
import '../services/analytics_service.dart';
import '../services/achievement_service.dart';
import '../l10n/app_localizations.dart';
import 'home.dart';

class RegistroCompletoSesionScreen extends StatefulWidget {
  const RegistroCompletoSesionScreen({super.key});

  @override
  State<RegistroCompletoSesionScreen> createState() =>
      _RegistroCompletoSesionScreenState();
}

class _RegistroCompletoSesionScreenState
    extends State<RegistroCompletoSesionScreen> {
  String _lugar = '';
  String _tipo = AppConstants.tipoEntrenamiento;
  final List<Partida> _partidas = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logScreenView('register_session_screen');
      } catch (e) {
        debugPrint('Error logging screen view: $e');
      }
    });
  }

  void anadirPartida() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroSesionScreen(
          onGuardar: (partida) {
            setState(() => _partidas.add(partida));
          },
        ),
      ),
    );
  }

  void editarPartida(int index) async {
    final partidaOriginal = _partidas[index];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarPartidaScreen(
          partida: partidaOriginal,
          onGuardar: (partidaActualizada) {
            setState(() {
              _partidas[index] = partidaActualizada;
            });
          },
        ),
      ),
    );
  }

  void borrarPartida(int index) {
    setState(() => _partidas.removeAt(index));
  }

  Future<void> _guardarSesion() async {
    if (_partidas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.addAtLeastOneGame),
        ),
      );
      return;
    }

    final nuevaSesion = Sesion(
      fecha: DateTime.now(),
      lugar: _lugar.trim(),
      tipo: _tipo.trim(),
      partidas: _partidas,
    );

    try {
      final dataRepository = Provider.of<DataRepository>(
        context,
        listen: false,
      );
      await dataRepository.guardarSesion(nuevaSesion);

      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await analytics.logSessionCreated(_tipo);

      // Verificar y desbloquear logros
      final achievementService = Provider.of<AchievementService>(context, listen: false);
      final newAchievements = await achievementService.checkAndUnlockAchievements();
      
      // Mostrar notificación de logros desbloqueados
      if (newAchievements.isNotEmpty && mounted) {
        for (var achievement in newAchievements) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '¡Logro Desbloqueado!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('${achievement.nameKey.split('.')[1].replaceAll('_', ' ').toUpperCase()} (+${achievement.xpReward} XP)'),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.sessionSavedSuccess),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error al guardar sesión: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.sessionSaveErrorMessage,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.registerSession),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: "Inicio",
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.location,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => _lugar = v,
            ),
            const SizedBox(height: 16),
            SelectorTipoPartida(
              value: _tipo,
              onChanged: (value) => setState(
                () => _tipo = value ?? AppConstants.tipoEntrenamiento,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.gamesCount(_partidas.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ElevatedButton.icon(
                  onPressed: anadirPartida,
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context)!.addGame),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListaPartidas(
                partidas: _partidas,
                onEditar: editarPartida,
                onBorrar: borrarPartida,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _guardarSesion,
              icon: const Icon(Icons.save),
              label: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );
  }
}
