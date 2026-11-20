import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';
import '../models/sesion.dart';
import 'season_assignment_store.dart';

/// Service for persisting and managing the list of seasons (temporadas) and
/// the currently active/default season used when registering a new session.
class TemporadaService {
  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns the persisted list of season names.  The list is ordered as the
  /// user left it (most recently created first by default on first use).
  /// Never includes [AppConstants.temporadaSinTemporada] – that option is
  /// always implied by the UI and stored as `null` in the active-season key.
  static Future<List<String>> getTemporadas({bool strict = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.prefKeyTemporadas);
      if (raw == null) return [];
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded.cast<String>();
    } catch (e) {
      debugPrint('TemporadaService: error loading seasons: $e');
      if (strict) rethrow;
      return [];
    }
  }

  /// Returns the name of the active/default season, or `null` if "Sin
  /// temporada" is selected as the default.
  static Future<String?> getTemporadaActiva() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // The key is absent when never set, and present with value '' to
      // represent "Sin temporada" explicitly.
      if (!prefs.containsKey(AppConstants.prefKeyTemporadaActiva)) {
        return null;
      }
      final value = prefs.getString(AppConstants.prefKeyTemporadaActiva);
      return (value == null || value.isEmpty) ? null : value;
    } catch (e) {
      debugPrint('TemporadaService: error loading active season: $e');
      return null;
    }
  }

  /// Names found in existing sessions remain manageable even after recovery
  /// onto another device. This does not silently claim preferences for a UID.
  static Future<List<String>> getTemporadasConSesiones(
    Iterable<Sesion> sessions,
  ) async {
    return {
      ...await getTemporadas(strict: true),
      ...sessions.map((s) => normalizeSeason(s.temporada)).whereType<String>(),
    }.toList();
  }

  static Future<List<String>> getTemporadasDisponibles(
    Iterable<Sesion> sessions,
  ) async {
    final archived = await getArchivedTemporadas(strict: true);
    return (await getTemporadasConSesiones(
      sessions,
    )).where((name) => !archived.contains(name)).toList();
  }

  /// Preserve the legacy year suggestion only if no choice has ever been saved.
  static Future<String?> getTemporadaPredeterminada({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(AppConstants.prefKeyTemporadaActiva)) {
      final year = (now ?? DateTime.now()).year.toString();
      return await isArchived(year) ? null : year;
    }
    final active = normalizeSeason(await getTemporadaActiva());
    return active != null && !await isArchived(active) ? active : null;
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  static Future<void> _saveTemporadas(List<String> temporadas) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      AppConstants.prefKeyTemporadas,
      json.encode(temporadas),
    )) {
      throw StateError('Cannot save seasons');
    }
  }

  /// Persists [name] as the active/default season.
  /// Pass `null` to set "Sin temporada" as the default.
  static Future<void> setTemporadaActiva(String? name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalized = normalizeSeason(name);
      if (normalized != null && await isArchived(normalized)) {
        throw StateError('Restore season before setting it as default');
      }
      if (!await prefs.setString(
        AppConstants.prefKeyTemporadaActiva,
        normalized ?? '',
      )) {
        throw StateError('Cannot save default season');
      }
    } catch (e) {
      debugPrint('TemporadaService: error saving active season: $e');
      rethrow;
    }
  }

  /// Adds [name] to the list if it is not already present and is not the
  /// reserved "Sin temporada" string.  Returns `true` if added.
  static Future<bool> addTemporada(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == AppConstants.temporadaSinTemporada) {
      return false;
    }
    try {
      final temporadas = await getTemporadas(strict: true);
      if (temporadas.any(
        (t) => t.trim().toLowerCase() == trimmed.toLowerCase(),
      ))
        return false;
      temporadas.insert(0, trimmed);
      await _saveTemporadas(temporadas);
      return true;
    } catch (e) {
      debugPrint('TemporadaService: error adding season: $e');
      return false;
    }
  }

  /// Renames [oldName] to [newName].  Also updates the active-season key if
  /// the renamed season was the active one.  Returns `true` on success.
  static Future<bool> renameTemporada(String oldName, String newName) async {
    final trimmedNew = newName.trim();
    if (trimmedNew.isEmpty ||
        trimmedNew == AppConstants.temporadaSinTemporada) {
      return false;
    }
    try {
      final temporadas = await getTemporadas(strict: true);
      final idx = temporadas.indexOf(oldName);
      if (idx == -1) return false;
      if (temporadas.any(
        (t) =>
            t != oldName && t.trim().toLowerCase() == trimmedNew.toLowerCase(),
      ))
        return false;
      temporadas[idx] = trimmedNew;
      await _saveTemporadas(temporadas);

      final archived = await getArchivedTemporadas(strict: true);
      if (archived.contains(oldName)) {
        await _saveArchivedTemporadas(
          archived.map((n) => n == oldName ? trimmedNew : n).toList(),
        );
      }
      // Keep active-season in sync
      final activa = await getTemporadaActiva();
      if (activa == oldName) {
        await setTemporadaActiva(
          archived.contains(oldName) ? null : trimmedNew,
        );
      }
      return true;
    } catch (e) {
      debugPrint('TemporadaService: error renaming season: $e');
      return false;
    }
  }

  /// Removes [name] from the list.  If [name] was the active season the
  /// active season is cleared (set to "Sin temporada").
  static Future<void> deleteTemporada(String name) async {
    try {
      final temporadas = await getTemporadas(strict: true);
      temporadas.remove(name);
      await _saveTemporadas(temporadas);

      // Also remove from archived list if present (skip I/O when not archived)
      if (await isArchived(name)) {
        final archivadas = await getArchivedTemporadas(strict: true);
        archivadas.remove(name);
        await _saveArchivedTemporadas(archivadas);
      }

      final activa = await getTemporadaActiva();
      if (activa == name) {
        await setTemporadaActiva(null);
      }
    } catch (e) {
      debugPrint('TemporadaService: error deleting season: $e');
      rethrow;
    }
  }

  // ── Archive ───────────────────────────────────────────────────────────────

  /// Returns the list of archived season names.
  static Future<List<String>> getArchivedTemporadas({
    bool strict = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.prefKeyTemporadasArchivadas);
      if (raw == null) return [];
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded.cast<String>();
    } catch (e) {
      debugPrint('TemporadaService: error loading archived seasons: $e');
      if (strict) rethrow;
      return [];
    }
  }

  static Future<void> _saveArchivedTemporadas(List<String> archivadas) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      AppConstants.prefKeyTemporadasArchivadas,
      json.encode(archivadas),
    )) {
      throw StateError('Cannot save archived seasons');
    }
  }

  /// Archives [name]: it stays in the main list (for historical filtering)
  /// but is additionally added to the archived list and cleared as active.
  /// Returns `true` on success.
  static Future<bool> archiveTemporada(String name) async {
    try {
      final temporadas = await getTemporadas(strict: true);
      if (!temporadas.contains(name)) return false;

      final archivadas = await getArchivedTemporadas(strict: true);
      if (!archivadas.contains(name)) {
        archivadas.add(name);
        await _saveArchivedTemporadas(archivadas);
      }

      // Clear active season if it was this one
      final activa = await getTemporadaActiva();
      if (activa == name) {
        await setTemporadaActiva(null);
      }
      return true;
    } catch (e) {
      debugPrint('TemporadaService: error archiving season: $e');
      return false;
    }
  }

  /// Restores an archived season back to active status (removes from archive
  /// list). Returns `true` on success.
  static Future<bool> unarchiveTemporada(String name) async {
    try {
      final archivadas = await getArchivedTemporadas(strict: true);
      if (archivadas.remove(name)) {
        await _saveArchivedTemporadas(archivadas);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('TemporadaService: error unarchiving season: $e');
      return false;
    }
  }

  /// Returns `true` if [name] is in the archived list.
  static Future<bool> isArchived(String name) async {
    final archivadas = await getArchivedTemporadas(strict: true);
    return archivadas.contains(name);
  }
}
