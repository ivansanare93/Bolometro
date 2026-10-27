import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/bowling_ball.dart';
import 'arsenal_remote_store.dart';

/// Per-account write-ahead journal, independent of the legacy model adapters.
/// No deletion reconciliation and no last-write-wins by device timestamp.
class ArsenalSyncService {
  final String uid;
  final Box<BowlingBall> balls;
  final Box<BallMaintenance> maintenance;
  final Box<dynamic> journal;
  final ArsenalRemoteStore remote;
  final VoidCallback onChanged;
  final Duration networkTimeout;
  Future<void> _localTail = Future.value();
  Future<void>? _syncing;
  bool paused = false;
  String? error;
  bool get isSyncing => _syncing != null;
  bool get hasConfirmedBackup => journal.containsKey('meta/confirmation');

  ArsenalSyncService({
    required this.uid,
    required this.balls,
    required this.maintenance,
    required this.journal,
    required this.remote,
    required this.onChanged,
    this.networkTimeout = const Duration(seconds: 15),
  });

  Map<String, dynamic> _state(String key) => Map<String, dynamic>.from(
    journal.get(key, defaultValue: <String, dynamic>{}) as Map,
  );

  List<String> get conflicts => journal.keys
      .cast<String>()
      .where((key) => _state(key)['conflict'] == true)
      .toList();
  int get pendingCount => journal.keys
      .cast<String>()
      .where((key) => _state(key)['pending'] == true)
      .length;

  Future<T> _exclusive<T>(Future<T> Function() action) {
    final result = _localTail.then((_) => action());
    _localTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  Map<String, dynamic>? _local(String collection, String id) =>
      collection == 'balls'
      ? balls.get(id)?.toJson()
      : maintenance.get(id)?.toJson();

  Future<void> _put(String collection, Map<String, dynamic> payload) async {
    final id = payload['id'] as String;
    validateArsenalPayload(collection, id, payload);
    if (collection == 'balls') {
      await balls.put(id, BowlingBall.fromJson(payload));
    } else {
      await maintenance.put(id, BallMaintenance.fromJson(payload));
    }
  }

  Future<void> save(String collection, Map<String, dynamic> payload) =>
      _exclusive(() async {
        if (paused) throw StateError('Account changed; edit was not saved');
        final key = '$collection/${payload['id']}';
        final state = _state(key);
        if (state['conflict'] == true) {
          throw StateError(
            'Resolve the saved conflict before editing this record',
          );
        }
        await _enqueue(key, payload, state);
        // Journal first: recovery can replay an interrupted local write.
        await _put(collection, payload);
        onChanged();
      });

  Future<void> _enqueue(
    String key,
    Map<String, dynamic> payload,
    Map<String, dynamic> state,
  ) async {
    final parts = key.split('/');
    await journal.put(key, {
      ...state,
      'pending': true,
      'payload': payload,
      'previousPayload': _local(parts[0], parts[1]),
      'operationId': generateStableId(),
    });
    await journal.flush();
  }

  /// Replay journal and discover edits made by an older application version.
  Future<void> recover() => _exclusive(() async {
    for (final key in journal.keys.cast<String>().toList()) {
      final state = _state(key);
      if ((state['pending'] == true || state['conflict'] == true) && state['payload'] != null) {
        final parts = key.split('/');
        final payload = Map<String, dynamic>.from(state['payload'] as Map);
        // A legacy client may have edited an already persisted local record.
        // Preserve that variant instead of silently replaying over it.
        final local = _local(parts[0], parts[1]);
        if (local != null &&
            !mapEquals(local, payload) &&
            !mapEquals(local, state['previousPayload'] as Map?)) {
          final previousVariant = state['legacyVariant'] as Map?;
          if (previousVariant != null && !mapEquals(previousVariant, local) &&
              state['legacyBackedUp'] != true) {
            paused = true;
            throw StateError('Several unconfirmed legacy variants; local copies retained for manual recovery.');
          }
          if (!mapEquals(previousVariant, local)) {
            state['legacyOperationId'] = generateStableId();
            state['legacyBackedUp'] = false;
          }
          state['legacyVariant'] = local;
          state['conflict'] = true;
          await journal.put(key, state);
        } else {
          await _put(parts[0], payload);
        }
      }
    }
    await _discover();
  });

  Future<void> _discover() async {
    final records = <String, Map<String, dynamic>>{
      for (final ball in balls.values) 'balls/${ball.id}': ball.toJson(),
      for (final item in maintenance.values)
        'ball_maintenance/${item.id}': item.toJson(),
    };
    for (final entry in records.entries) {
      final state = _state(entry.key);
      if (state['pending'] != true &&
          state['conflict'] != true &&
          !mapEquals(state['basePayload'] as Map?, entry.value)) {
        await _enqueue(entry.key, entry.value, state);
      }
    }
  }

  Future<void> sync() {
    if (paused) return Future.error(StateError('Account is no longer active'));
    return _syncing ??= _run().whenComplete(() {
      _syncing = null;
      onChanged();
    });
  }

  Future<void> _run() async {
    error = null;
    onChanged();
    try {
      await _exclusive(_discover);
      final keys = journal.keys.cast<String>().toList()
        ..sort((a, b) {
          final aBall = a.startsWith('balls/');
          final bBall = b.startsWith('balls/');
          return aBall == bBall ? a.compareTo(b) : (aBall ? -1 : 1);
        });
      for (final key in keys) {
        if (paused) return;
        final state = await _exclusive(() async => _state(key));
        if (state['pending'] != true &&
            !(state['legacyVariant'] != null && state['legacyBackedUp'] != true)) continue;
        final parts = key.split('/');
        final payload = Map<String, dynamic>.from(state['payload'] as Map);
        final result = await remote
            .write(
              uid,
              parts[0],
              parts[1],
              state['revision'] as int? ?? 0,
              state['operationId'] as String,
              payload,
            )
            .timeout(networkTimeout);
        if (paused) return;
        await _exclusive(() async {
          final latest = _state(key);
          final sameOperation = latest['operationId'] == state['operationId'];
          if (result.conflict) {
            await journal.put(key, {
              ...latest,
              'conflict': true,
              'remotePayload': result.record.payload,
              'remoteRevision': result.record.revision,
            });
          } else {
            await journal.put(key, {
              ...latest,
              'revision': result.record.revision,
              'basePayload': result.record.payload,
              'pending': !sameOperation,
              if (latest['conflict'] == true) ...{
                'remotePayload': result.record.payload,
                'remoteRevision': result.record.revision,
              },
            });
          }
          await journal.flush();
        });
        if (state['legacyVariant'] != null && state['legacyBackedUp'] != true) {
          // Preserve legacy edits outside the journal before resolving them.
          final archived = await remote.write(uid, parts[0], parts[1], 0,
              state['legacyOperationId'] as String,
              Map<String, dynamic>.from(state['legacyVariant'] as Map))
              .timeout(networkTimeout);
          if (paused) return;
          await _exclusive(() async {
            await journal.put(key, {..._state(key), 'legacyBackedUp': true,
              'remotePayload': archived.record.payload,
              'remoteRevision': archived.record.revision});
            await journal.flush();
          });
        }
      }
      // Merge records individually; absence from server never deletes local data.
      for (final collection in ['balls', 'ball_maintenance']) {
        if (paused) return;
        final records = await remote
            .read(uid, collection)
            .timeout(networkTimeout);
        if (paused) return;
        await _exclusive(() async {
          final remoteIds = records.map((record) => record.id).toSet();
          final localIds = collection == 'balls'
              ? balls.values.map((ball) => ball.id)
              : maintenance.values.map((item) => item.id);
          for (final id in localIds) {
            final state = _state('$collection/$id');
            if (state['pending'] != true && !remoteIds.contains(id)) {
              throw StateError('A previously backed-up record is absent from the server; local copy retained.');
            }
          }
          for (final record in records) {
            validateArsenalPayload(collection, record.id, record.payload);
            final key = '$collection/${record.id}';
            final state = _state(key);
            if (state['pending'] == true || state['conflict'] == true) continue;
            // Journal the downloaded payload first, too, to survive a crash.
            await journal.put(key, {
              'revision': record.revision,
              'basePayload': record.payload,
              'payload': record.payload,
              'previousPayload': _local(collection, record.id),
              'pending': true,
              'operationId': generateStableId(),
            });
            await journal.flush();
            await _put(collection, record.payload);
            await journal.put(key, {
              'revision': record.revision,
              'basePayload': record.payload,
              'pending': false,
            });
          }
        });
      }
      if (!paused)
        await journal.put('meta/confirmation', {
          'confirmedAt': DateTime.now().toUtc().toIso8601String(),
        });
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      onChanged();
    }
  }

  Map<String, dynamic> conflict(String key) => _state(key);

  Future<List<ArsenalVersion>> history(String collection, String id) =>
      remote.history(uid, collection, id).timeout(networkTimeout);

  Future<void> restoreVersion(String collection, ArsenalVersion version) =>
      _exclusive(() async {
        if (paused) throw StateError('La cuenta ha cambiado');
        final key = '$collection/${version.record.id}';
        final state = _state(key);
        if (state['pending'] == true || state['conflict'] == true) {
          throw StateError(
            'Respalda o resuelve la versión actual antes de restaurar otra.',
          );
        }
        await _enqueue(key, version.record.payload, state);
        await _put(collection, version.record.payload);
        onChanged();
      });

  Future<void> importIfAbsent(
    String collection,
    Map<String, dynamic> payload,
  ) => _exclusive(() async {
    if (paused) throw StateError('Account changed');
    final id = payload['id'] as String;
    final local = _local(collection, id);
    if (local != null) {
      if (!mapEquals(local, payload))
        throw StateError('ID collision; copies retained');
      return;
    }
    final key = '$collection/$id';
    await _enqueue(key, payload, _state(key));
    await _put(collection, payload);
  });

  /// Both variants remain in server history; choosing never changes identity.
  Future<void> resolve(String key, {required bool keepLocal}) =>
      _exclusive(() async {
        if (paused) throw StateError('Account changed');
        final state = _state(key);
        if (state['conflict'] != true || state['remotePayload'] == null) {
          throw StateError('Synchronize to retrieve the remote conflict first');
        }
        if (state['legacyVariant'] != null && state['legacyBackedUp'] != true) {
          throw StateError('Sincroniza para respaldar ambas versiones antes de elegir.');
        }
        final payload = Map<String, dynamic>.from(
          (keepLocal
                  ? state['legacyVariant'] ?? state['payload']
                  : state['remotePayload'])
              as Map,
        );
        await _enqueue(key, payload, {
          'revision': state['remoteRevision'],
          'basePayload': state['remotePayload'],
        });
        await _put(key.split('/')[0], payload);
        onChanged();
      });

  Future<void> pause() async {
    paused = true;
    await _localTail;
    await journal.flush();
  }
}
