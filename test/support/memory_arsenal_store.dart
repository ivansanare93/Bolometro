import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:bolometro/services/arsenal_remote_store.dart';

/// Transactional test double; never imports or initializes a Firebase app.
class MemoryArsenalStore implements ArsenalRemoteStore {
  final records = <String, ArsenalRecord>{};
  final operations = <String, ArsenalWriteResult>{};
  final owners = <String>[];
  Object? writeError;
  Object? readError;
  bool loseNextAcknowledgement = false;
  Completer<void>? writeGate;
  Completer<void>? writeEntered;

  Map<String, dynamic> _copy(Map<String, dynamic> payload) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(payload)) as Map);

  @override
  Future<List<ArsenalRecord>> read(String uid, String collection) async {
    owners.add(uid);
    if (readError != null) throw readError!;
    final prefix = '$uid/$collection/';
    return records.entries
        .where((e) => e.key.startsWith(prefix))
        .map(
          (e) => ArsenalRecord(
            e.value.id,
            e.value.revision,
            _copy(e.value.payload),
          ),
        )
        .toList();
  }

  @override
  Future<ArsenalWriteResult> write(
    String uid,
    String collection,
    String id,
    int baseRevision,
    String operationId,
    Map<String, dynamic> payload,
  ) async {
    owners.add(uid);
    if (writeEntered?.isCompleted == false) writeEntered!.complete();
    if (writeGate != null) await writeGate!.future;
    if (writeError != null) throw writeError!;
    final key = '$uid/$collection/$id';
    final historyKey = '$key/$operationId';
    if (operations.containsKey(historyKey)) return operations[historyKey]!;
    final current = records[key];
    if (current != null && mapEquals(current.payload, payload)) {
      return ArsenalWriteResult(current);
    }
    final conflict = (current?.revision ?? 0) != baseRevision;
    final accepted = ArsenalRecord(id, baseRevision + 1, _copy(payload));
    final result = ArsenalWriteResult(
      conflict ? current! : accepted,
      conflict: conflict,
    );
    // History stores the rejected payload as well as the result returned.
    operations[historyKey] = result;
    variants[historyKey] = _copy(payload);
    if (!conflict) records[key] = accepted;
    if (loseNextAcknowledgement) {
      loseNextAcknowledgement = false;
      throw StateError('unavailable after server commit');
    }
    return result;
  }

  final variants = <String, Map<String, dynamic>>{};

  @override
  Future<List<ArsenalVersion>> history(
    String uid,
    String collection,
    String id,
  ) async {
    final prefix = '$uid/$collection/$id/';
    return operations.entries
        .where((e) => e.key.startsWith(prefix))
        .map(
          (entry) => ArsenalVersion(
            entry.key.substring(prefix.length),
            entry.value.conflict ? 'conflict' : 'accepted',
            ArsenalRecord(
              id,
              entry.value.record.revision,
              _copy(variants[entry.key]!),
            ),
          ),
        )
        .toList();
  }
}
