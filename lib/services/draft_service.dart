import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/partida.dart';

/// Service for persisting draft state of in-progress sessions and games.
/// Used to restore data when the app is killed in the background by Android.
class DraftService {
  static const String _sesionDraftKey = 'draft_sesion_completa';
  static const String _partidaDraftKey = 'draft_partida_actual';

  // ── Session draft (RegistroCompletoSesionScreen) ──────────────────────────

  static Future<void> saveSesionDraft({
    required String lugar,
    required String tipo,
    required List<Partida> partidas,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = {
        'lugar': lugar,
        'tipo': tipo,
        'partidas': partidas.map((p) => p.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_sesionDraftKey, json.encode(draft));
    } catch (e) {
      debugPrint('DraftService: error saving session draft: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadSesionDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftStr = prefs.getString(_sesionDraftKey);
      if (draftStr == null) return null;
      return json.decode(draftStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('DraftService: error loading session draft: $e');
      return null;
    }
  }

  static Future<void> clearSesionDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sesionDraftKey);
    } catch (e) {
      debugPrint('DraftService: error clearing session draft: $e');
    }
  }

  // ── Game draft (RegistroSesionScreen) ─────────────────────────────────────

  /// Saves the current in-progress game state to SharedPreferences.
  ///
  /// [framesText] is a 10-element list (one per frame), each frame being a
  /// list of up to 3 throw values as strings (e.g. "X", "/", "7", "-", "").
  ///
  /// [pinesPorTiro] mirrors the structure of [framesText] but stores the
  /// visual pin selection: for each frame and each throw, either a list of
  /// knocked-down pin indices (1–10) or null if no visual selection was made.
  static Future<void> savePartidaDraft({
    required List<List<String>> framesText,
    String? notas,
    required List<List<List<int>?>> pinesPorTiro,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final framesJson = framesText.map((f) => f.join(',')).toList();
      final pinesJson = pinesPorTiro.map((frame) {
        return frame.map((tiro) {
          if (tiro == null) return 'null';
          return tiro.join(',');
        }).join(';');
      }).toList();
      final draft = {
        'framesText': framesJson,
        'notas': notas,
        'pinesPorTiro': pinesJson,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_partidaDraftKey, json.encode(draft));
    } catch (e) {
      debugPrint('DraftService: error saving game draft: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadPartidaDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftStr = prefs.getString(_partidaDraftKey);
      if (draftStr == null) return null;
      return json.decode(draftStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('DraftService: error loading game draft: $e');
      return null;
    }
  }

  static Future<void> clearPartidaDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_partidaDraftKey);
    } catch (e) {
      debugPrint('DraftService: error clearing game draft: $e');
    }
  }
}
