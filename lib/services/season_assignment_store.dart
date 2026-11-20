import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/sesion.dart';
import '../utils/app_constants.dart';

String? normalizeSeason(String? value) {
  final name = value?.trim();
  return name == null ||
          name.isEmpty ||
          name == AppConstants.temporadaSinTemporada
      ? null
      : name;
}

class SeasonAssignmentConflict implements Exception {
  final String message;
  SeasonAssignmentConflict(this.message);
  @override
  String toString() => message;
}

/// Returns false for an already applied patch (including a lost acknowledgement).
bool shouldPatchSeason(String? current, String? expected, String? target) {
  if (normalizeSeason(current) == normalizeSeason(target)) return false;
  if (normalizeSeason(current) != normalizeSeason(expected)) {
    throw SeasonAssignmentConflict('remote_season_changed');
  }
  return true;
}

class SeasonAssignmentResult {
  final int updated;
  final int pending;
  final int conflicts;
  const SeasonAssignmentResult({
    this.updated = 0,
    this.pending = 0,
    this.conflicts = 0,
  });
}

/// Write-ahead journal of session season changes. No Hive adapters or session
/// identifiers change. Remote writes are compare-and-set patches of one field.
class SeasonAssignmentStore {
  final Box<Sesion> sessions;
  final Box<dynamic> journal;
  final bool Function() isCurrent;
  final Future<void> Function(DateTime, String?, String?)? patchRemote;

  SeasonAssignmentStore({
    required this.sessions,
    required this.journal,
    required this.isCurrent,
    this.patchRemote,
  });

  static final _tails = <String, Future<void>>{};

  Future<T> _locked<T>(Future<T> Function() action) {
    final key = journal.path ?? journal.name;
    final previous = _tails[key] ?? Future<void>.value();
    final next = previous.then((_) => action());
    final barrier = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _tails[key] = barrier;
    barrier.then((_) {
      if (identical(_tails[key], barrier)) _tails.remove(key);
    });
    return next;
  }

  Future<void> recover() => _locked(_recover);

  Future<SeasonAssignmentResult> assign(
    List<Sesion> selected,
    String? destination,
  ) => _locked(() => _assign(selected, destination));

  Future<SeasonAssignmentResult> retry() => _locked(_retry);

  Future<void> resolve(
    String id,
    String? remoteValue, {
    required bool useLocal,
  }) => _locked(() => _resolve(id, remoteValue, useLocal: useLocal));

  // Hive restores nested maps with dynamic keys; JSON restores the wire types
  // expected by the existing session/game parsers without changing adapters.
  Sesion _snapshot(dynamic value) =>
      Sesion.fromJson(jsonDecode(jsonEncode(value)) as Map<String, dynamic>);

  void _check() {
    if (!isCurrent()) throw StateError('Season operation: account changed');
  }

  dynamic _key(DateTime date) {
    final matches = sessions.keys
        .where(
          (key) =>
              sessions.get(key)!.fecha.millisecondsSinceEpoch ==
              date.millisecondsSinceEpoch,
        )
        .toList();
    if (matches.length > 1) {
      throw StateError('Ambiguous session identifier');
    }
    return matches.isEmpty ? null : matches.single;
  }

  /// Replays only an interrupted local write. A divergent local season is
  /// retained as a conflict rather than silently restored from an old snapshot.
  Future<void> _recover() async {
    _check();
    for (final id in journal.keys.toList()) {
      _check();
      final entry = Map<String, dynamic>.from(journal.get(id) as Map);
      if (entry['localApplied'] == true) continue;
      final snapshot = _snapshot(entry['session']);
      final key = _key(snapshot.fecha);
      final current = key == null ? null : sessions.get(key);
      final expected = normalizeSeason(entry['localExpected'] as String?);
      final target = normalizeSeason(entry['target'] as String?);
      if (current != null &&
          normalizeSeason(current.temporada) != expected &&
          normalizeSeason(current.temporada) != target) {
        entry['status'] = 'conflict';
        entry['error'] = 'local_season_changed';
        await journal.put(id, entry);
        _check();
        continue;
      }
      final updated = (current ?? snapshot).copyWith(
        temporada: target,
        clearTemporada: target == null,
      );
      if (key == null) {
        await sessions.add(updated);
      } else {
        await sessions.put(key, updated);
      }
      _check();
      entry['localApplied'] = true;
      await journal.put(id, entry);
      _check();
    }
  }

  Future<SeasonAssignmentResult> _assign(
    List<Sesion> selected,
    String? destination,
  ) async {
    await _recover();
    final target = normalizeSeason(destination);
    final plan = <String, Map<String, dynamic>>{};
    // Validate the whole selection before journaling or mutating any session.
    for (final session in selected) {
      _check();
      final id = session.fecha.millisecondsSinceEpoch.toString();
      if (plan.containsKey(id)) throw StateError('Duplicate session selection');
      if (journal.containsKey(id)) {
        throw StateError('Resolve or retry pending season changes first');
      }
      final key = _key(session.fecha);
      final current = key == null ? session : sessions.get(key)!;
      if (normalizeSeason(current.temporada) !=
          normalizeSeason(session.temporada)) {
        throw SeasonAssignmentConflict('Local season changed; reload sessions');
      }
      if (normalizeSeason(current.temporada) == target) continue;
      plan[id] = {
        'session': current.toJson(),
        'expected': normalizeSeason(current.temporada),
        'localExpected': normalizeSeason(current.temporada),
        'target': target,
        'localApplied': false,
        'status': 'pending',
      };
    }
    await journal.putAll(plan);
    _check();
    await _recover();
    for (final id in plan.keys) {
      if ((journal.get(id) as Map)['localApplied'] != true) {
        throw SeasonAssignmentConflict('Local season write could not complete');
      }
    }
    if (patchRemote == null) {
      // Guest writes are durable locally; no account is implicitly assigned.
      for (final id in plan.keys) {
        final entry = journal.get(id) as Map;
        if (entry['localApplied'] != true) {
          throw SeasonAssignmentConflict(
            'Local season write could not complete',
          );
        }
        await journal.delete(id);
        _check();
      }
      return SeasonAssignmentResult(updated: plan.length);
    }
    final result = await _retry();
    return SeasonAssignmentResult(
      updated: plan.length,
      pending: result.pending,
      conflicts: result.conflicts,
    );
  }

  Future<SeasonAssignmentResult> _retry() async {
    await _recover();
    if (patchRemote == null) {
      for (final id in journal.keys.toList()) {
        if ((journal.get(id) as Map)['localApplied'] == true) {
          await journal.delete(id);
          _check();
        }
      }
      return summary();
    }
    for (final id in journal.keys.toList()) {
      _check();
      final entry = Map<String, dynamic>.from(journal.get(id) as Map);
      if (entry['localApplied'] != true || entry['status'] == 'conflict')
        continue;
      try {
        await patchRemote!(
          DateTime.parse((entry['session'] as Map)['fecha'] as String),
          entry['expected'] as String?,
          entry['target'] as String?,
        );
        _check();
        await journal.delete(id);
        _check();
      } catch (error) {
        _check();
        entry['status'] = error is SeasonAssignmentConflict
            ? 'conflict'
            : 'pending';
        entry['error'] = error.toString();
        await journal.put(id, entry);
        _check();
      }
    }
    return summary();
  }

  /// The UI must obtain a fresh server value and explicitly ask the user.
  /// Resolution checks that value again through compare-and-set before writing.
  Future<void> _resolve(
    String id,
    String? remoteValue, {
    required bool useLocal,
  }) async {
    _check();
    final raw = journal.get(id);
    if (raw == null) return;
    final entry = Map<String, dynamic>.from(raw as Map);
    if (entry['status'] != 'conflict')
      throw StateError('Not a season conflict');
    final snapshot = _snapshot(entry['session']);
    final key = _key(snapshot.fecha);
    final current = key == null ? null : sessions.get(key);
    if (current == null ||
        normalizeSeason(current.temporada) !=
            normalizeSeason(entry['target'] as String?)) {
      throw SeasonAssignmentConflict('Local session changed; review again');
    }
    if (useLocal) {
      await patchRemote!(
        snapshot.fecha,
        remoteValue,
        entry['target'] as String?,
      );
      _check();
    } else {
      await sessions.put(
        key,
        current.copyWith(
          temporada: normalizeSeason(remoteValue),
          clearTemporada: normalizeSeason(remoteValue) == null,
        ),
      );
      _check();
    }
    await journal.delete(id);
    _check();
  }

  SeasonAssignmentResult summary() {
    _check();
    final entries = journal.values.cast<Map>().toList();
    return SeasonAssignmentResult(
      pending: entries.length,
      conflicts: entries.where((e) => e['status'] == 'conflict').length,
    );
  }

  /// Overlay pending *season fields* on fresh server sessions. Other remote
  /// fields are preserved; locally retained sessions remain visible on failure.
  List<Sesion> overlay(List<Sesion> remote) {
    _check();
    final byId = {
      for (final s in remote) s.fecha.millisecondsSinceEpoch.toString(): s,
    };
    for (final id in journal.keys) {
      final entry = journal.get(id) as Map;
      if (entry['localApplied'] != true) continue;
      final snapshot = _snapshot(entry['session']);
      final target = entry['target'] as String?;
      byId[id as String] = (byId[id] ?? snapshot).copyWith(
        temporada: target,
        clearTemporada: target == null,
      );
    }
    return byId.values.toList();
  }
}
