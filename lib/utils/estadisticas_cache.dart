import 'dart:convert';
import 'stats_selection.dart';
import 'package:flutter/foundation.dart';
import '../models/sesion.dart';
import '../models/partida.dart';
import 'estadisticas_utils.dart';
import 'app_constants.dart';

/// Cache para optimizar cálculos estadísticos
/// Evita recalcular estadísticas en cada rebuild
class EstadisticasCache extends ChangeNotifier {
  Map<String, dynamic>? _cache;
  DateTime? _lastUpdate;
  String? _accountId;
  bool _boundAccount = false;
  final Map<
    String,
    ({String content, Map<String, dynamic> stats, DateTime time})
  >
  _entries = {};

  /// Bounded, account-scoped cache. Compare serialized content, not just counts
  /// or object identity: legacy session lists and pin arrays can be mutated.
  Map<String, dynamic> getEstadisticas(
    List<Sesion> sesiones, {
    String filterKey = '',
    String? accountId,
  }) {
    if (!_boundAccount || _accountId != accountId) {
      _entries.clear();
      _cache = null;
      _lastUpdate = null;
      _accountId = accountId;
      _boundAccount = true;
    }
    final ordered = StatsSelection.chronologicalSessions(sesiones);
    final content = jsonEncode(ordered.map((s) => s.toJson()).toList());
    final entry = _entries[filterKey];
    final now = DateTime.now();
    if (entry != null &&
        entry.content == content &&
        now.difference(entry.time) <
            const Duration(minutes: AppConstants.cacheExpirationMinutes)) {
      return entry.stats;
    }
    final partidas = StatsSelection.games(ordered).map((e) => e.$2).toList();
    final stats = _calcularEstadisticas(ordered, partidas);
    if (_entries.length >= 32 && !_entries.containsKey(filterKey)) {
      _entries.remove(_entries.keys.first);
    }
    _entries[filterKey] = (content: content, stats: stats, time: now);
    _cache = stats;
    _lastUpdate = now;
    // Reading statistics is allowed during build; do not notify from a getter.
    return stats;
  }

  /// Calcular todas las estadísticas
  Map<String, dynamic> _calcularEstadisticas(
    List<Sesion> sesiones,
    List<Partida> partidas,
  ) {
    if (partidas.isEmpty) {
      return {..._getEmptyStats(), 'totalSesiones': sesiones.length};
    }

    final partidasFrames = partidas.map((p) => p.frames).toList();

    // Calcular estadísticas
    final porcentajes = EstadisticasUtils.calcularPorcentajes(partidasFrames);
    final rachaStrikes = EstadisticasUtils.rachaMaximaDe(
      AppConstants.simboloStrike,
      partidasFrames,
    );
    final rachaSpares = EstadisticasUtils.rachaMaximaDe(
      AppConstants.simboloSpare,
      partidasFrames,
    );

    final promedioGeneral = partidas.isEmpty
        ? 0.0
        : partidas.map((p) => p.total).reduce((a, b) => a + b) /
              partidas.length;

    final mejorPartida = partidas.isEmpty
        ? null
        : partidas.reduce((a, b) => a.total > b.total ? a : b);

    final peorPartida = partidas.isEmpty
        ? null
        : partidas.reduce((a, b) => a.total < b.total ? a : b);

    final sesionRecord = EstadisticasUtils.sesionRecord(
      sesiones.where((s) => s.partidas.isNotEmpty).toList(),
    );
    final sesionPeor = EstadisticasUtils.sesionPeor(
      sesiones.where((s) => s.partidas.isNotEmpty).toList(),
    );

    final mejorEntrenamiento = EstadisticasUtils.mejorPuntuacionPorTipo(
      sesiones,
      AppConstants.tipoEntrenamiento,
    );
    final mejorCompeticion = EstadisticasUtils.mejorPuntuacionPorTipo(
      sesiones,
      AppConstants.tipoCompeticion,
    );

    final promedioUltimas5 = EstadisticasUtils.promedioUltimasPartidas(
      partidas,
      AppConstants.ultimasPartidasPromedio5,
    );
    final promedioUltimas10 = EstadisticasUtils.promedioUltimasPartidas(
      partidas,
      AppConstants.ultimasPartidasPromedio10,
    );

    final histograma = EstadisticasUtils.calcularHistograma(
      partidas,
      binSize: AppConstants.histogramaBinSize,
    );

    final topMejores = EstadisticasUtils.topNPartidas(
      partidas,
      AppConstants.maxPartidasTop,
      mejores: true,
    );
    final topPeores = EstadisticasUtils.topNPartidas(
      partidas,
      AppConstants.maxPartidasTop,
      mejores: false,
    );

    // Calculate moving average (expensive operation, cached here)
    final promedioMovil = EstadisticasUtils.promedioMovil(
      partidas,
      AppConstants.ventanaPromedioMovil,
    );

    // Calcular estadísticas basadas en datos de pines (teclado visual)
    final promedioPrimerTiro = EstadisticasUtils.calcularPromedioPrimerTiro(
      partidas,
    );
    final tasaConversionSpare = EstadisticasUtils.calcularTasaConversionSpare(
      partidas,
    );
    final conversionSparePorPin =
        EstadisticasUtils.calcularConversionSparePorPin(partidas);

    return {
      'porcentajes': porcentajes,
      'rachaStrikes': rachaStrikes,
      'rachaSpares': rachaSpares,
      'promedioGeneral': promedioGeneral,
      'mejorPartida': mejorPartida,
      'peorPartida': peorPartida,
      'sesionRecord': sesionRecord,
      'sesionPeor': sesionPeor,
      'mejorEntrenamiento': mejorEntrenamiento,
      'mejorCompeticion': mejorCompeticion,
      'promedioUltimas5': promedioUltimas5,
      'promedioUltimas10': promedioUltimas10,
      'histograma': histograma,
      'topMejores': topMejores,
      'topPeores': topPeores,
      'promedioMovil': promedioMovil,
      'totalPartidas': partidas.length,
      'totalSesiones': sesiones.length,
      'promedioPrimerTiro': promedioPrimerTiro,
      'tasaConversionSpare': tasaConversionSpare,
      'conversionSparePorPin': conversionSparePorPin,
    };
  }

  /// Obtener estadísticas vacías
  Map<String, dynamic> _getEmptyStats() {
    return {
      'porcentajes': {'strikes': 0.0, 'spares': 0.0, 'fallos': 0.0},
      'rachaStrikes': 0,
      'rachaSpares': 0,
      'promedioGeneral': 0.0,
      'mejorPartida': null,
      'peorPartida': null,
      'sesionRecord': null,
      'sesionPeor': null,
      'mejorEntrenamiento': 0,
      'mejorCompeticion': 0,
      'promedioUltimas5': 0.0,
      'promedioUltimas10': 0.0,
      'histograma': <String, int>{},
      'topMejores': <Partida>[],
      'topPeores': <Partida>[],
      'promedioMovil': <double>[],
      'totalPartidas': 0,
      'totalSesiones': 0,
      'promedioPrimerTiro': null,
      'tasaConversionSpare': null,
      'conversionSparePorPin': <String, List<int>>{},
    };
  }

  /// Forzar recalculo de estadísticas
  void invalidateCache() {
    _cache = null;
    _lastUpdate = null;
    _entries.clear();
    notifyListeners();
  }

  /// Verificar si el cache está activo
  bool get hasCache => _cache != null;

  /// Obtener tiempo desde última actualización
  Duration? get timeSinceLastUpdate {
    if (_lastUpdate == null) return null;
    return DateTime.now().difference(_lastUpdate!);
  }
}
