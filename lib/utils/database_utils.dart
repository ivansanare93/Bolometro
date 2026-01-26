import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/sesion.dart';
import 'app_constants.dart';

/// Cargar sesiones desde Hive con manejo robusto de errores
Future<List<Sesion>> cargarSesionesDesdeHive() async {
  try {
    final box = Hive.box<Sesion>(AppConstants.boxSesiones);
    return box.values.toList();
  } on HiveError catch (e) {
    // Error específico de Hive
    debugPrint('Error de Hive al cargar sesiones: $e');
    // Intentar recuperación si la box está corrupta
    try {
      await Hive.deleteBoxFromDisk(AppConstants.boxSesiones);
      await Hive.openBox<Sesion>(AppConstants.boxSesiones);
      debugPrint('Box de sesiones recreada después de error');
      return [];
    } catch (recoveryError) {
      debugPrint('No se pudo recuperar la box: $recoveryError');
      return [];
    }
  } catch (e) {
    // Error genérico
    debugPrint('Error inesperado al cargar sesiones: $e');
    return [];
  }
}

/// Guardar sesión en Hive con manejo de errores
Future<bool> guardarSesionEnHive(Sesion sesion) async {
  try {
    final box = Hive.box<Sesion>(AppConstants.boxSesiones);
    await box.add(sesion);
    return true;
  } on HiveError catch (e) {
    debugPrint('Error de Hive al guardar sesión: $e');
    return false;
  } catch (e) {
    debugPrint('Error inesperado al guardar sesión: $e');
    return false;
  }
}

/// Eliminar sesión de Hive con manejo de errores
Future<bool> eliminarSesionDeHive(int index) async {
  try {
    final box = Hive.box<Sesion>(AppConstants.boxSesiones);
    if (index < 0 || index >= box.length) {
      debugPrint('Índice fuera de rango: $index');
      return false;
    }
    await box.deleteAt(index);
    return true;
  } on HiveError catch (e) {
    debugPrint('Error de Hive al eliminar sesión: $e');
    return false;
  } catch (e) {
    debugPrint('Error inesperado al eliminar sesión: $e');
    return false;
  }
}
