import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';

/// Service for persisting and retrieving the list of previously used locations.
/// Locations are stored in [SharedPreferences] as a JSON-encoded list ordered
/// most-recently-used first.
class LugarService {
  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns the persisted list of location names, most-recently-used first.
  static Future<List<String>> getLugares() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.prefKeyLugares);
      if (raw == null) return [];
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded.cast<String>();
    } catch (e) {
      debugPrint('LugarService: error loading locations: $e');
      return [];
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  static Future<void> _saveLugares(List<String> lugares) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefKeyLugares, json.encode(lugares));
  }

  /// Adds [name] to the top of the list if it is not already present.
  /// If it already exists it is moved to the top (most-recently-used).
  /// Empty strings are ignored.
  /// Returns `true` if the list was modified.
  static Future<bool> addLugar(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    try {
      final lugares = await getLugares();
      lugares.remove(trimmed);
      lugares.insert(0, trimmed);
      await _saveLugares(lugares);
      return true;
    } catch (e) {
      debugPrint('LugarService: error adding location: $e');
      return false;
    }
  }

  /// Removes [name] from the list.
  static Future<void> deleteLugar(String name) async {
    try {
      final lugares = await getLugares();
      lugares.remove(name);
      await _saveLugares(lugares);
    } catch (e) {
      debugPrint('LugarService: error deleting location: $e');
    }
  }
}
