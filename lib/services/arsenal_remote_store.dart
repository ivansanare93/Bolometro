import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

void validateArsenalPayload(
  String collection,
  String id,
  Map<String, dynamic> p,
) {
  bool date(Object? value) =>
      value is String && DateTime.tryParse(value) != null;
  if (id.isEmpty || id.contains('/') || p['id'] != id) {
    throw const FormatException('Invalid arsenal identity; data retained');
  }
  final ball = collection == 'balls';
  final valid = ball
      ? p['name'] is String &&
            (p['name'] as String).isNotEmpty &&
            p['weightLbs'] is num &&
            (p['weightLbs'] as num).isFinite &&
            (p['weightLbs'] as num) > 0 &&
            p['isActive'] is bool &&
            date(p['createdAt']) &&
            date(p['updatedAt']) &&
            (p['purchaseDate'] == null || date(p['purchaseDate']))
      : collection == 'ball_maintenance' &&
            p['ballId'] is String &&
            (p['ballId'] as String).isNotEmpty &&
            p['type'] is String &&
            date(p['date']);
  if (!valid)
    throw const FormatException('Incomplete arsenal payload; data retained');
}

class ArsenalRecord {
  final String id;
  final int revision;
  final Map<String, dynamic> payload;
  const ArsenalRecord(this.id, this.revision, this.payload);
}

class ArsenalWriteResult {
  final bool conflict;
  final ArsenalRecord record;
  const ArsenalWriteResult(this.record, {this.conflict = false});
}

class ArsenalVersion {
  final String operationId;
  final String kind;
  final ArsenalRecord record;
  const ArsenalVersion(this.operationId, this.kind, this.record);
}

/// All reads must reach the server: cached data is not a confirmed backup.
abstract class ArsenalRemoteStore {
  Future<List<ArsenalRecord>> read(String uid, String collection);
  Future<List<ArsenalVersion>> history(
    String uid,
    String collection,
    String id,
  );
  Future<ArsenalWriteResult> write(
    String uid,
    String collection,
    String id,
    int baseRevision,
    String operationId,
    Map<String, dynamic> payload,
  );
}

class FirestoreArsenalStore implements ArsenalRemoteStore {
  final FirebaseFirestore? _instance;
  FirestoreArsenalStore({FirebaseFirestore? firestore}) : _instance = firestore;
  FirebaseFirestore get _db => _instance ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(
    String uid,
    String name,
  ) {
    if (!['balls', 'ball_maintenance'].contains(name)) {
      throw ArgumentError.value(name, 'collection');
    }
    return _db.collection('users').doc(uid).collection(name);
  }

  ArsenalRecord _record(
    Map<String, dynamic> data,
    String id,
    String collection,
  ) {
    final payload = Map<String, dynamic>.from(data['payload'] as Map);
    final revision = data['revision'] as int;
    if (revision < 1 || data['id'] != id || payload['id'] != id) {
      throw const FormatException(
        'Invalid arsenal record; local data retained',
      );
    }
    validateArsenalPayload(collection, id, payload);
    return ArsenalRecord(id, revision, payload);
  }

  @override
  Future<List<ArsenalRecord>> read(String uid, String collection) async {
    final result = await _collection(
      uid,
      collection,
    ).get(const GetOptions(source: Source.server));
    return result.docs
        .map((doc) => _record(doc.data(), doc.id, collection))
        .toList();
  }

  @override
  Future<List<ArsenalVersion>> history(
    String uid,
    String collection,
    String id,
  ) async {
    final snapshot = await _collection(uid, collection)
        .doc(id)
        .collection('revisions')
        .get(const GetOptions(source: Source.server));
    final versions = snapshot.docs
        .map(
          (doc) => ArsenalVersion(
            doc.id,
            doc.data()['kind'] as String,
            _record(doc.data(), id, collection),
          ),
        )
        .toList();
    versions.sort((a, b) => b.record.revision.compareTo(a.record.revision));
    return versions;
  }

  @override
  Future<ArsenalWriteResult> write(
    String uid,
    String collection,
    String id,
    int baseRevision,
    String operationId,
    Map<String, dynamic> payload,
  ) {
    final ref = _collection(uid, collection).doc(id);
    final revisionRef = ref.collection('revisions').doc(operationId);
    return _db.runTransaction((transaction) async {
      final current = await transaction.get(ref);
      final previous = await transaction.get(revisionRef);
      final currentRecord = current.exists
          ? _record(current.data()!, id, collection)
          : null;
      if (previous.exists) {
        final old = previous.data()!;
        if (!mapEquals(
          Map<String, dynamic>.from(old['payload'] as Map),
          payload,
        )) {
          throw StateError('Operation ID reused with different payload');
        }
        if (old['kind'] == 'conflict') {
          return ArsenalWriteResult(currentRecord!, conflict: true);
        }
        return ArsenalWriteResult(_record(old, id, collection));
      }
      final conflict = (currentRecord?.revision ?? 0) != baseRevision;
      if (currentRecord != null && mapEquals(currentRecord.payload, payload)) {
        return ArsenalWriteResult(currentRecord);
      }
      final revision = conflict ? currentRecord!.revision : baseRevision + 1;
      final envelope = <String, dynamic>{
        'id': id,
        'revision': revision,
        'baseRevision': baseRevision,
        'operationId': operationId,
        'payload': payload,
        'kind': conflict ? 'conflict' : 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      // Keep rejected edits remotely as well, so reinstall cannot erase them.
      transaction.set(revisionRef, envelope);
      if (conflict) {
        return ArsenalWriteResult(currentRecord!, conflict: true);
      }
      transaction.set(ref, envelope);
      return ArsenalWriteResult(ArsenalRecord(id, revision, payload));
    });
  }
}
