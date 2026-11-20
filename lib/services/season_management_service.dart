import '../models/sesion.dart';
import '../repositories/data_repository.dart';
import 'season_assignment_store.dart';
import 'temporada_service.dart';

/// Coordinates metadata and session reassignment without deleting any session.
class SeasonManagementService {
  final DataRepository repository;
  SeasonManagementService(this.repository);

  Future<List<Sesion>> _sessions(String name) async =>
      (await repository.obtenerSesionesConfirmadasParaTemporadas())
          .where((s) => normalizeSeason(s.temporada) == name)
          .toList();

  void _checkSelection(List<Sesion> sessions, Set<int>? expected) {
    if (expected == null) return;
    final actual = sessions.map((s) => s.fecha.millisecondsSinceEpoch).toSet();
    if (actual.length != expected.length || !actual.containsAll(expected)) {
      throw StateError('Session selection changed; confirm again');
    }
  }

  Future<void> _ready() async {
    if ((await repository.estadoCambiosTemporada()).pending > 0) {
      throw StateError('Retry or review pending season changes first');
    }
  }

  Future<SeasonAssignmentResult> rename(
    String source,
    String destination, {
    Set<int>? expectedSessionIds,
  }) async {
    await _ready();
    final uid = repository.seasonAccountToken;
    final target = normalizeSeason(destination);
    if (target == null) throw ArgumentError('Empty season name');
    final all = await TemporadaService.getTemporadasConSesiones(
      await repository.obtenerSesionesConfirmadasParaTemporadas(),
    );
    if (!all.contains(source)) throw StateError('Unknown season');
    if (all.any(
      (name) => name != source && name.toLowerCase() == target.toLowerCase(),
    )) {
      throw StateError('Season name already exists');
    }
    final affected = await _sessions(source);
    _checkSelection(affected, expectedSessionIds);
    if (repository.seasonAccountToken != uid)
      throw StateError('Account changed');
    final result = await repository.asignarTemporadaEnLote(affected, target);
    if (repository.seasonAccountToken != uid)
      throw StateError('Account changed');
    // Names recovered solely from sessions are registered before editing.
    if (!(await TemporadaService.getTemporadas(
      strict: true,
    )).contains(source)) {
      if (!await TemporadaService.addTemporada(source))
        throw StateError('Cannot register season');
    }
    if (!await TemporadaService.renameTemporada(source, target)) {
      throw StateError(
        'Sessions preserved; season metadata could not be renamed',
      );
    }
    return result;
  }

  Future<SeasonAssignmentResult> remove(
    String source,
    String? destination, {
    Set<int>? expectedSessionIds,
  }) async {
    await _ready();
    final uid = repository.seasonAccountToken;
    final target = normalizeSeason(destination);
    if (source == target) throw ArgumentError('Choose another season');
    if (target != null && await TemporadaService.isArchived(target)) {
      throw StateError('Restore destination season first');
    }
    final affected = await _sessions(source);
    _checkSelection(affected, expectedSessionIds);
    if (repository.seasonAccountToken != uid)
      throw StateError('Account changed');
    final result = await repository.asignarTemporadaEnLote(affected, target);
    if (repository.seasonAccountToken != uid)
      throw StateError('Account changed');
    await TemporadaService.deleteTemporada(source);
    return result;
  }
}
