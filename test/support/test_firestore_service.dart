import 'package:bolometro/models/nota.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/services/firestore_service.dart';

/// Minimal remote notes double for existing account isolation tests.
class TestFirestoreService extends FirestoreService {
  @override
  Future<List<Sesion>> obtenerSesiones(String userId) async => [];
  final notes = <String, Map<String, Map<String, dynamic>>>{};
  @override
  Future<void> guardarNota(String userId, Nota nota) async {
    (notes[userId] ??= {})[nota.id] = nota.toJson();
  }

  @override
  Future<List<Nota>> obtenerNotas(
    String userId, {
    bool includeDeleted = false,
  }) async => (notes[userId]?.values ?? <Map<String, dynamic>>[])
      .map(Nota.fromJson)
      .where((n) => includeDeleted || n.fechaEliminacion == null)
      .toList();
}
