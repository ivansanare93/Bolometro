import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../models/sesion.dart';
import '../models/partida.dart';
import '../models/nota.dart';
import '../services/analytics_service.dart';
import '../repositories/data_repository.dart';
import '../widgets/score_sheet_pin_strip.dart';
import 'editar_partida.dart';
import 'registro_sesion.dart';
import 'editar_nota_screen.dart';
import 'ver_nota_screen.dart';
import 'home.dart';
import '../l10n/app_localizations.dart';
import '../utils/compartir_sesion.dart';
import '../utils/registro_tiros_utils.dart';

class VerSesion extends StatefulWidget {
  final Sesion sesion;
  const VerSesion({super.key, required this.sesion});

  @override
  State<VerSesion> createState() => _VerSesionState();
}

class _VerSesionState extends State<VerSesion> {
  late Sesion sesionActual;
  late Future<List<Nota>> _relatedNotesFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logScreenView('view_session_screen');
      } catch (e) {
        debugPrint('Error logging screen view: $e');
      }
    });
    sesionActual = widget.sesion;
    _relatedNotesFuture = _obtenerNotasRelacionadas();
  }

  Future<void> _editarPartida(int index) async {
    final partidaOriginal = sesionActual.partidas[index];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarPartidaScreen(
          partida: partidaOriginal,
          onGuardar: (partidaActualizada) async {
            try {
              final dataRepository = Provider.of<DataRepository>(context, listen: false);

              final nuevasPartidas = List<Partida>.from(sesionActual.partidas);
              nuevasPartidas[index] = partidaActualizada;

              final sesionActualizada = sesionActual.copyWith(partidas: nuevasPartidas);
              await dataRepository.actualizarSesion(sesionActualizada);

              setState(() {
                sesionActual = sesionActualizada;
              });

              Navigator.pop(context); // Cierra edición
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.gameUpdated),
                    backgroundColor: Colors.green[600],
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } on HiveError catch (e) {
              debugPrint('Error de Hive al actualizar partida: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.gameUpdateError),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              debugPrint('Error al actualizar partida: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.gameUnexpectedUpdateError),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _eliminarPartida(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteGameTitle),
        content: Text(AppLocalizations.of(context)!.deleteGameConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final dataRepository = Provider.of<DataRepository>(context, listen: false);

        final nuevasPartidas = List<Partida>.from(sesionActual.partidas)
          ..removeAt(index);

        final sesionActualizada = sesionActual.copyWith(partidas: nuevasPartidas);
        await dataRepository.actualizarSesion(sesionActualizada);

        setState(() {
          sesionActual = sesionActualizada;
        });

        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        await analytics.logGameDeleted();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.gameDeletedSuccess),
              backgroundColor: Colors.orange[600],
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } on HiveError catch (e) {
        debugPrint('Error de Hive al eliminar partida: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.gameDeleteErrorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error al eliminar partida: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.gameUnexpectedDeleteError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _anadirPartida() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroSesionScreen(
          onGuardar: (nuevaPartida) async {
            try {
              final dataRepository = Provider.of<DataRepository>(context, listen: false);

              final nuevasPartidas = List<Partida>.from(sesionActual.partidas)
                ..add(nuevaPartida);

              final sesionActualizada = sesionActual.copyWith(partidas: nuevasPartidas);
              await dataRepository.actualizarSesion(sesionActualizada);

              setState(() {
                sesionActual = sesionActualizada;
              });

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.gameAdded),
                    backgroundColor: Colors.green[600],
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } on HiveError catch (e) {
              debugPrint('Error de Hive al añadir partida: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.gameUpdateError),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              debugPrint('Error al añadir partida: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.gameUnexpectedUpdateError),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _editarLugarSesion() async {
    final dataRepository = Provider.of<DataRepository>(context, listen: false);
    var valorLugar = sesionActual.lugar.trim();
    final nuevoLugar = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text('${dialogL10n.edit} ${dialogL10n.location}'),
          content: TextFormField(
            initialValue: valorLugar,
            decoration: InputDecoration(
              labelText: dialogL10n.location,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            autofocus: true,
            onChanged: (value) => valorLugar = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dialogL10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, valorLugar),
              child: Text(dialogL10n.save),
            ),
          ],
        );
      },
    );

    final lugarNormalizado = nuevoLugar?.trim();
    if (!mounted ||
        lugarNormalizado == null ||
        lugarNormalizado == sesionActual.lugar) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    try {
      final sesionActualizada = sesionActual.copyWith(lugar: lugarNormalizado);
      await dataRepository.actualizarSesion(sesionActualizada);

      if (!mounted) return;
      setState(() {
        sesionActual = sesionActualizada;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveSuccess)),
      );
    } catch (e) {
      debugPrint('Error al actualizar lugar de sesión: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sessionSaveErrorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editarTemporadaSesion() async {
    final dataRepository = Provider.of<DataRepository>(context, listen: false);
    var valorTemporada = sesionActual.temporada ?? '';
    final nuevaTemporada = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: const Text('Editar temporada'),
          content: TextFormField(
            initialValue: valorTemporada,
            decoration: const InputDecoration(
              labelText: 'Temporada',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            autofocus: true,
            onChanged: (value) => valorTemporada = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dialogL10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, valorTemporada),
              child: Text(dialogL10n.save),
            ),
          ],
        );
      },
    );

    if (nuevaTemporada == null) {
      return;
    }
    final temporadaNormalizada = nuevaTemporada.trim();
    final temporadaActual = sesionActual.temporada?.trim();
    if (!mounted || temporadaNormalizada == temporadaActual) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;

    try {
      final sesionActualizada =
          temporadaNormalizada.isEmpty
              ? sesionActual.copyWith(clearTemporada: true)
              : sesionActual.copyWith(temporada: temporadaNormalizada);
      await dataRepository.actualizarSesion(sesionActualizada);

      if (!mounted) return;
      setState(() {
        sesionActual = sesionActualizada;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveSuccess)),
      );
    } catch (e) {
      debugPrint('Error al actualizar temporada de sesión: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sessionSaveErrorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Returns true if the game was recorded with the pin keyboard
  /// (i.e. at least one throw has pin selection data).
  bool _hasPinData(Partida partida) {
    return partida.pinesPorTiro.any(
      (frame) => frame.any((tiro) => tiro != null),
    );
  }

  String get _sessionId => sesionActual.fecha.millisecondsSinceEpoch.toString();

  Future<List<Nota>> _obtenerNotasRelacionadas() async {
    final repo = Provider.of<DataRepository>(context, listen: false);
    final notas = await repo.obtenerNotas();
    final relacionadas =
        notas.where((n) => n.relatedSessionId == _sessionId).toList();
    relacionadas.sort((a, b) => b.fechaModificacion.compareTo(a.fechaModificacion));
    return relacionadas;
  }

  void _refreshRelatedNotes() {
    setState(() {
      _relatedNotesFuture = _obtenerNotasRelacionadas();
    });
  }

  Future<void> _mostrarOpcionesCompartir({
    required String title,
    required Future<void> Function() onShareText,
    required Future<void> Function() onShareImage,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(l10n.chooseShareFormat),
                ),
                ListTile(
                  leading: const Icon(Icons.text_snippet_outlined),
                  title: Text(l10n.shareAsText),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await onShareText();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: Text(l10n.shareAsImage),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await onShareImage();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _compartirSesion() {
    final l10n = AppLocalizations.of(context)!;
    return _mostrarOpcionesCompartir(
      title: l10n.shareSession,
      onShareText: () => compartirSesionComoTexto(context, sesionActual),
      onShareImage: () => compartirSesionComoImagen(context, sesionActual),
    );
  }

  Future<void> _compartirPartida(int index) {
    final l10n = AppLocalizations.of(context)!;
    final partida = sesionActual.partidas[index];
    return _mostrarOpcionesCompartir(
      title: l10n.shareGame,
      onShareText: () => compartirPartidaComoTexto(
        context,
        sesionActual,
        partida,
        index + 1,
      ),
      onShareImage: () => compartirPartidaComoImagen(
        context,
        sesionActual,
        partida,
        index + 1,
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, String estado) {
    switch (estado) {
      case NotaEstado.pendiente:
        return l10n.noteStatusPending;
      case NotaEstado.probado:
        return l10n.noteStatusTested;
      case NotaEstado.validado:
        return l10n.noteStatusValidated;
      case NotaEstado.descartado:
        return l10n.noteStatusDiscarded;
      default:
        return l10n.noteStatusPending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final esEntrenamiento = sesionActual.tipo.toLowerCase() == 'entrenamiento';
    final colorTipo = esEntrenamiento
        ? Theme.of(context).colorScheme.primary
        : Colors.red.shade700;
    final tipoLabel = esEntrenamiento ? l10n.training : l10n.competition;

    // RESUMEN
    final promedio = sesionActual.partidas.isNotEmpty
        ? (sesionActual.partidas.map((p) => p.total).reduce((a, b) => a + b) /
                  sesionActual.partidas.length)
              .toStringAsFixed(1)
        : '-';

    final mejor = sesionActual.partidas.isEmpty
        ? '-'
        : sesionActual.partidas
              .map((p) => p.total)
              .reduce((a, b) => a > b ? a : b)
              .toString();

    final peor = sesionActual.partidas.isEmpty
        ? '-'
        : sesionActual.partidas
              .map((p) => p.total)
              .reduce((a, b) => a < b ? a : b)
              .toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$tipoLabel • ${sesionActual.lugar.isNotEmpty ? sesionActual.lugar : l10n.noLocation}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: AppLocalizations.of(context)!.shareSession,
            onPressed: _compartirSesion,
          ),
          IconButton(
            icon: const Icon(Icons.edit_location_alt),
            tooltip: AppLocalizations.of(context)!.edit,
            onPressed: _editarLugarSesion,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_view_month),
            tooltip: 'Temporada',
            onPressed: _editarTemporadaSesion,
          ),
          IconButton(
            icon: const Icon(Icons.note_add_outlined),
            tooltip: AppLocalizations.of(context)!.newNote,
            onPressed: () async {
              final relatedSessionId =
                  _sessionId;
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditarNotaScreen(
                    initialRelatedSessionId: relatedSessionId,
                  ),
                ),
              );
              if (created == true && mounted) {
                _refreshRelatedNotes();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.noteSaved),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: AppLocalizations.of(context)!.home,
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // RESUMEN SESION
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            margin: const EdgeInsets.only(bottom: 18),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        esEntrenamiento
                            ? Icons.fitness_center
                            : Icons.emoji_events,
                        color: colorTipo,
                        size: 32,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        tipoLabel.toUpperCase(),
                        style: TextStyle(
                          color: colorTipo,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.grey[600],
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${sesionActual.fecha.day}/${sesionActual.fecha.month}/${sesionActual.fecha.year}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_view_month_rounded,
                        color: colorTipo,
                        size: 20,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          sesionActual.temporadaNormalizada,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (sesionActual.notas != null &&
                      sesionActual.notas!.trim().isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.sticky_note_2, color: colorTipo, size: 20),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            sesionActual.notas!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _KpiSmall(
                        title: AppLocalizations.of(context)!.average,
                        value: promedio,
                        color: Colors.blue[700]!,
                      ),
                      _KpiSmall(
                        title: AppLocalizations.of(context)!.best,
                        value: mejor,
                        color: Colors.green[700]!,
                      ),
                      _KpiSmall(
                        title: AppLocalizations.of(context)!.worst,
                        value: peor,
                        color: Colors.red[400]!,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          FutureBuilder<List<Nota>>(
            future: _relatedNotesFuture,
            builder: (context, snapshot) {
              final notas = snapshot.data ?? const <Nota>[];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 18),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sticky_note_2_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.sessionRelatedNotes(notas.length),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final created = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditarNotaScreen(
                                    initialRelatedSessionId: _sessionId,
                                  ),
                                ),
                              );
                              if (created == true && mounted) {
                                _refreshRelatedNotes();
                              }
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: Text(l10n.newNote),
                          ),
                        ],
                      ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Semantics(
                            label: l10n.loading,
                            child: const LinearProgressIndicator(minHeight: 2),
                          ),
                        )
                      else if (notas.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            l10n.sessionNoRelatedNotes,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      else ...[
                        const SizedBox(height: 8),
                        ...notas.take(3).map(
                          (nota) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              nota.titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(_statusLabel(l10n, nota.estado)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () async {
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VerNotaScreen(nota: nota),
                                ),
                              );
                              if (changed == true && mounted) {
                                _refreshRelatedNotes();
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          // PARTIDAS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.gamesListCount(sesionActual.partidas.length),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _anadirPartida,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.addGame),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (sesionActual.partidas.isEmpty)
            Center(
              child: Text(
                AppLocalizations.of(context)!.noGamesRegistered,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ...sesionActual.partidas.asMap().entries.map((entry) {
            final idx = entry.key;
            final partida = entry.value;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 7),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.gameNumber(idx + 1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share_outlined),
                          tooltip: AppLocalizations.of(context)!.shareGame,
                          onPressed: () => _compartirPartida(idx),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: AppLocalizations.of(context)!.editTooltip,
                          onPressed: () => _editarPartida(idx),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: AppLocalizations.of(context)!.deleteTooltip,
                          onPressed: () => _eliminarPartida(idx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(Icons.scoreboard, size: 20, color: colorTipo),
                        const SizedBox(width: 5),
                        Text(
                          AppLocalizations.of(context)!.points(partida.total),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorTipo,
                          ),
                        ),
                        if (partida.notas != null &&
                            partida.notas!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Icon(
                              Icons.sticky_note_2,
                              size: 18,
                              color: Colors.amber[800],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Marcador visual (frames)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(10, (i) {
                          final frame = partida.frames[i];
                          final isLast = i == 9;
                          final tiros = isLast
                              ? frame.take(3).toList()
                              : frame.take(2).toList();

                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(6),
                              color: Theme.of(context).cardColor,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'F${i + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: tiros.map((t) {
                                    return Container(
                                      width: 24,
                                      height: 28,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade500,
                                        ),
                                        color: isDark
                                            ? Colors.grey.shade800
                                            : Colors.white,
                                       ),
                                       child: Text(
                                         formatearTiroParaMostrar(t),
                                         style: TextStyle(
                                           fontFamily: 'monospace',
                                           fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    // Pin detail section (only for games recorded with pin keyboard)
                    if (_hasPinData(partida)) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.my_location,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.pinsPerThrow,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ScoreSheetPinStrip(
                        pinesPorTiro: partida.pinesPorTiro,
                      ),
                    ],
                    if (partida.notas != null &&
                        partida.notas!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.note, size: 20, color: Colors.amber[800]),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              partida.notas!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _KpiSmall extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _KpiSmall({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: color.withOpacity(0.82),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
