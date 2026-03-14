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
import '../services/draft_service.dart';
import '../l10n/app_localizations.dart';
import 'home.dart';

class RegistroCompletoSesionScreen extends StatefulWidget {
  const RegistroCompletoSesionScreen({super.key});

  @override
  State<RegistroCompletoSesionScreen> createState() =>
      _RegistroCompletoSesionScreenState();
}

class _RegistroCompletoSesionScreenState
    extends State<RegistroCompletoSesionScreen>
    with WidgetsBindingObserver {
  String _lugar = '';
  String _tipo = AppConstants.tipoEntrenamiento;
  final List<Partida> _partidas = [];

  // TextEditingController to keep the location field in sync with restored draft
  final TextEditingController _lugarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreDraftIfAvailable();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logScreenView('register_session_screen');
      } catch (e) {
        debugPrint('Error logging screen view: $e');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lugarController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveDraft();
    }
  }

  void _saveDraft() {
    DraftService.saveSesionDraft(
      lugar: _lugar,
      tipo: _tipo,
      partidas: _partidas,
    );
  }

  Future<void> _restoreDraftIfAvailable() async {
    final draft = await DraftService.loadSesionDraft();
    if (draft == null) return;

    final savedPartidas = (draft['partidas'] as List<dynamic>?)
        ?.map((p) => Partida.fromJson(p as Map<String, dynamic>))
        .toList();

    final savedLugar = (draft['lugar'] as String?) ?? '';
    final savedTipo = (draft['tipo'] as String?) ?? AppConstants.tipoEntrenamiento;

    final hasData = (savedPartidas != null && savedPartidas.isNotEmpty) ||
        savedLugar.isNotEmpty;

    if (!hasData) return;

    if (mounted) {
      setState(() {
        _lugar = savedLugar;
        _tipo = savedTipo;
        if (savedPartidas != null) {
          _partidas.clear();
          _partidas.addAll(savedPartidas);
        }
        _lugarController.text = savedLugar;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.draftRestoredSession),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void anadirPartida() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroSesionScreen(
          onGuardar: (partida) {
            setState(() => _partidas.add(partida));
            _saveDraft();
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
            _saveDraft();
          },
        ),
      ),
    );
  }

  void borrarPartida(int index) {
    setState(() => _partidas.removeAt(index));
    _saveDraft();
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
      await DraftService.clearSesionDraft();

      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await analytics.logSessionCreated(_tipo);

      // Verificar y desbloquear logros
      final achievementService = Provider.of<AchievementService>(context, listen: false);
      final newAchievements = await achievementService.checkAndUnlockAchievements();
      
      // Mostrar notificación de logros desbloqueados
      if (newAchievements.isNotEmpty && mounted) {
        final l10n = AppLocalizations.of(context);
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
                        Text(
                          l10n!.achievementUnlocked,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(_getAchievementName(l10n, achievement.id) + ' (+${achievement.xpReward} XP)'),
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

  String _getAchievementName(AppLocalizations l10n, String achievementId) {
    final nameMap = {
      'first_game': l10n.achievementFirstGameName,
      'games_10': l10n.achievementGames10Name,
      'games_50': l10n.achievementGames50Name,
      'games_100': l10n.achievementGames100Name,
      'strikes_10': l10n.achievementStrikes10Name,
      'strikes_50': l10n.achievementStrikes50Name,
      'strikes_100': l10n.achievementStrikes100Name,
      'score_150': l10n.achievementScore150Name,
      'score_200': l10n.achievementScore200Name,
      'score_250': l10n.achievementScore250Name,
      'perfect_game': l10n.achievementPerfectGameName,
      'streak_3': l10n.achievementStreak3Name,
      'streak_5': l10n.achievementStreak5Name,
      'spares_20': l10n.achievementSpares20Name,
      'spares_100': l10n.achievementSpares100Name,
    };
    return nameMap[achievementId] ?? achievementId;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) DraftService.clearSesionDraft();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.registerSession),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              tooltip: AppLocalizations.of(context)!.home,
              onPressed: () {
                DraftService.clearSesionDraft();
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
                controller: _lugarController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.location,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) {
                  _lugar = v;
                  _saveDraft();
                },
              ),
              const SizedBox(height: 16),
              SelectorTipoPartida(
                value: _tipo,
                onChanged: (value) {
                  setState(
                    () => _tipo = value ?? AppConstants.tipoEntrenamiento,
                  );
                  _saveDraft();
                },
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
      ),
    );
  }
}
