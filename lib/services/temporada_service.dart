import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';

/// Service for persisting and managing the list of seasons (temporadas) and
/// the currently active/default season used when registering a new session.
class TemporadaService {
  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns the persisted list of season names.  The list is ordered as the
  /// user left it (most recently created first by default on first use).
  /// Never includes [AppConstants.temporadaSinTemporada] – that option is
  /// always implied by the UI and stored as `null` in the active-season key.
  static Future<List<String>> getTemporadas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.prefKeyTemporadas);
      if (raw == null) return [];
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded.cast<String>();
    } catch (e) {
      debugPrint('TemporadaService: error loading seasons: $e');
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

  // ── Write ─────────────────────────────────────────────────────────────────

  static Future<void> _saveTemporadas(List<String> temporadas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.prefKeyTemporadas, json.encode(temporadas));
  }

  /// Persists [name] as the active/default season.
  /// Pass `null` to set "Sin temporada" as the default.
  static Future<void> setTemporadaActiva(String? name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefKeyTemporadaActiva, name ?? '');
    } catch (e) {
      debugPrint('TemporadaService: error saving active season: $e');
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
      final temporadas = await getTemporadas();
      if (temporadas.contains(trimmed)) return false;
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
    if (trimmedNew.isEmpty || trimmedNew == AppConstants.temporadaSinTemporada) {
      return false;
    }
    try {
      final temporadas = await getTemporadas();
      final idx = temporadas.indexOf(oldName);
      if (idx == -1) return false;
      if (temporadas.contains(trimmedNew) && trimmedNew != oldName) return false;
      temporadas[idx] = trimmedNew;
      await _saveTemporadas(temporadas);

      // Keep active-season in sync
      final activa = await getTemporadaActiva();
      if (activa == oldName) {
        await setTemporadaActiva(trimmedNew);
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
      final temporadas = await getTemporadas();
      temporadas.remove(name);
      await _saveTemporadas(temporadas);

      // Also remove from archived list if present (skip I/O when not archived)
      if (await isArchived(name)) {
        final archivadas = await getArchivedTemporadas();
        archivadas.remove(name);
        await _saveArchivedTemporadas(archivadas);
      }

      final activa = await getTemporadaActiva();
      if (activa == name) {
        await setTemporadaActiva(null);
      }
    } catch (e) {
      debugPrint('TemporadaService: error deleting season: $e');
    }
  }

  // ── Archive ───────────────────────────────────────────────────────────────

  /// Returns the list of archived season names.
  static Future<List<String>> getArchivedTemporadas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.prefKeyTemporadasArchivadas);
      if (raw == null) return [];
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded.cast<String>();
    } catch (e) {
      debugPrint('TemporadaService: error loading archived seasons: $e');
      return [];
    }
  }

  static Future<void> _saveArchivedTemporadas(
      List<String> archivadas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.prefKeyTemporadasArchivadas, json.encode(archivadas));
  }

  /// Archives [name]: it stays in the main list (for historical filtering)
  /// but is additionally added to the archived list and cleared as active.
  /// Returns `true` on success.
  static Future<bool> archiveTemporada(String name) async {
    try {
      final temporadas = await getTemporadas();
      if (!temporadas.contains(name)) return false;

      final archivadas = await getArchivedTemporadas();
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
      final archivadas = await getArchivedTemporadas();
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
    final archivadas = await getArchivedTemporadas();
    return archivadas.contains(name);
  }
}
