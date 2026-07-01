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
import '../services/lugar_service.dart';
import '../services/temporada_service.dart';
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
  String _temporada = DateTime.now().year.toString();
  List<String> _temporadasDisponibles = [];
  List<String> _lugaresDisponibles = [];
  final List<Partida> _partidas = [];

  // TextEditingController to keep the location field in sync with restored draft
  final TextEditingController _lugarController = TextEditingController();
  final FocusNode _lugarFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDefaults();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logScreenView('register_session_screen');
      } catch (e) {
        debugPrint('Error logging screen view: $e');
      }
    });
  }

  /// Loads the available seasons and the active season, then checks for a
  /// draft.  Draft values always take precedence over the active-season
  /// default so that an in-progress session is never silently overwritten.
  Future<void> _initializeDefaults() async {
    final temporadas = await TemporadaService.getTemporadas();
    final activa = await TemporadaService.getTemporadaActiva();
    final lugares = await LugarService.getLugares();

    if (mounted) {
      setState(() {
        _temporadasDisponibles = temporadas;
        if (activa != null) {
          _temporada = activa;
        }
        _lugaresDisponibles = lugares;
      });
    }

    await _restoreDraftIfAvailable();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lugarController.dispose();
    _lugarFocusNode.dispose();
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
      temporada: _temporada,
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
    final savedTemporada =
        (draft['temporada'] as String?) ?? DateTime.now().year.toString();

    final hasData = (savedPartidas != null && savedPartidas.isNotEmpty) ||
        savedLugar.isNotEmpty ||
        savedTemporada.trim() != DateTime.now().year.toString();

    if (!hasData) return;

    if (mounted) {
      setState(() {
        _lugar = savedLugar;
        _tipo = savedTipo;
        _temporada = savedTemporada;
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
      temporada:
          _temporada.trim().isEmpty ? null : _temporada.trim(),
    );

    try {
      final dataRepository = Provider.of<DataRepository>(
        context,
        listen: false,
      );
      await dataRepository.guardarSesion(nuevaSesion);
      await DraftService.clearSesionDraft();
      await LugarService.addLugar(_lugar);

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
              RawAutocomplete<String>(
                textEditingController: _lugarController,
                focusNode: _lugarFocusNode,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _lugaresDisponibles;
                  }
                  return _lugaresDisponibles.where(
                    (lugar) => lugar.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        ),
                  ).toList();
                },
                onSelected: (String selected) {
                  _lugar = selected;
                  _saveDraft();
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.location,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      _lugar = v;
                      _saveDraft();
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              leading: const Icon(Icons.location_on_outlined, size: 18),
                              title: Text(option),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
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
              const SizedBox(height: 16),
              _TemporadaSelector(
                value: _temporada,
                temporadas: _temporadasDisponibles,
                onChanged: (v) {
                  setState(() => _temporada = v);
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
              SafeArea(
                top: false,
                child: ElevatedButton.icon(
                  onPressed: _guardarSesion,
                  icon: const Icon(Icons.save),
                  label: Text(AppLocalizations.of(context)!.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Season selector ────────────────────────────────────────────────────────

/// Shows a dropdown of known seasons (from [TemporadaService]) plus a
/// "Sin temporada" option, with a trailing icon that opens a text dialog to
/// type a fully custom name.
class _TemporadaSelector extends StatelessWidget {
  final String value;
  final List<String> temporadas;
  final ValueChanged<String> onChanged;

  const _TemporadaSelector({
    required this.value,
    required this.temporadas,
    required this.onChanged,
  });

  Future<void> _showCustomDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    // Empty string and "Sin temporada" are the same; don't pre-fill them as
    // text – let the user type a new value from scratch.
    final prefill = (value.isEmpty || value == AppConstants.temporadaSinTemporada)
        ? ''
        : value;
    final controller = TextEditingController(text: prefill);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.selectSeason),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.newSeasonHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.accept),
          ),
        ],
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build the dropdown items: known seasons + Sin temporada
    final knownOptions = [
      ...temporadas,
      AppConstants.temporadaSinTemporada,
    ];

    // If the current value isn't in the list (custom text), still show it.
    // Empty string is normalised to "Sin temporada" for display purposes.
    final effectiveValue = value.isEmpty ? AppConstants.temporadaSinTemporada : value;
    final isCustom = effectiveValue != AppConstants.temporadaSinTemporada &&
        !temporadas.contains(effectiveValue);
    final dropdownValue = isCustom ? null : effectiveValue;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.selectSeason,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          tooltip: l10n.selectSeason,
          onPressed: () => _showCustomDialog(context),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          isDense: true,
          value: dropdownValue,
          hint: isCustom
              ? Text(
                  effectiveValue,
                  style: TextStyle(color: cs.onSurface),
                )
              : null,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: knownOptions.map((option) {
            final isSinTemporada = option == AppConstants.temporadaSinTemporada;
            return DropdownMenuItem(
              value: option,
              child: Row(
                children: [
                  Icon(
                    isSinTemporada
                        ? Icons.remove_circle_outline
                        : Icons.event_note_rounded,
                    size: 16,
                    color: isSinTemporada
                        ? cs.onSurface.withOpacity(0.45)
                        : isDark
                            ? cs.primary
                            : cs.primary.withOpacity(0.8),
                  ),
                  const SizedBox(width: 8),
                  Text(option,
                      style: TextStyle(
                        fontStyle: isSinTemporada
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: isSinTemporada
                            ? cs.onSurface.withOpacity(0.6)
                            : null,
                      )),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
