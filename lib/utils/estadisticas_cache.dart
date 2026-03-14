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
  int _lastSesionesCount = 0;
  int _lastPartidasCount = 0;

  /// Obtener estadísticas con cache
  Map<String, dynamic> getEstadisticas(List<Sesion> sesiones) {
    final todasPartidas = <Partida>[];
    for (final sesion in sesiones) {
      todasPartidas.addAll(sesion.partidas);
    }

    // Verificar si necesitamos recalcular
    if (_shouldRefresh(sesiones.length, todasPartidas.length)) {
      _cache = _calcularEstadisticas(sesiones, todasPartidas);
      _lastUpdate = DateTime.now();
      _lastSesionesCount = sesiones.length;
      _lastPartidasCount = todasPartidas.length;
      notifyListeners();
    }

    return _cache ?? {};
  }

  /// Determinar si el cache debe refrescarse
  bool _shouldRefresh(int sesionesCount, int partidasCount) {
    // Si no hay cache, refrescar
    if (_cache == null || _lastUpdate == null) {
      return true;
    }

    // Si cambió la cantidad de sesiones o partidas, refrescar
    if (sesionesCount != _lastSesionesCount ||
        partidasCount != _lastPartidasCount) {
      return true;
    }

    // Si pasó el tiempo de expiración, refrescar
    if (DateTime.now().difference(_lastUpdate!).inMinutes >
        AppConstants.cacheExpirationMinutes) {
      return true;
    }

    return false;
  }

  /// Calcular todas las estadísticas
  Map<String, dynamic> _calcularEstadisticas(
    List<Sesion> sesiones,
    List<Partida> partidas,
  ) {
    if (partidas.isEmpty) {
      return _getEmptyStats();
    }

    final partidasFrames =
        partidas.map((p) => p.frames).toList();

    // Calcular estadísticas
    final porcentajes =
        EstadisticasUtils.calcularPorcentajes(partidasFrames);
    final rachaStrikes =
        EstadisticasUtils.rachaMaximaDe(AppConstants.simboloStrike, partidasFrames);
    final rachaSpares =
        EstadisticasUtils.rachaMaximaDe(AppConstants.simboloSpare, partidasFrames);

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

    final sesionRecord = EstadisticasUtils.sesionRecord(sesiones);
    final sesionPeor = EstadisticasUtils.sesionPeor(sesiones);

    final mejorEntrenamiento = EstadisticasUtils.mejorPuntuacionPorTipo(
      sesiones,
      AppConstants.tipoEntrenamiento,
    );
    final mejorCompeticion = EstadisticasUtils.mejorPuntuacionPorTipo(
      sesiones,
      AppConstants.tipoCompeticion,
    );

    final promedioUltimas5 =
        EstadisticasUtils.promedioUltimasPartidas(partidas, AppConstants.ultimasPartidasPromedio5);
    final promedioUltimas10 =
        EstadisticasUtils.promedioUltimasPartidas(partidas, AppConstants.ultimasPartidasPromedio10);

    final histograma =
        EstadisticasUtils.calcularHistograma(partidas, binSize: AppConstants.histogramaBinSize);

    final topMejores =
        EstadisticasUtils.topNPartidas(partidas, AppConstants.maxPartidasTop, mejores: true);
    final topPeores =
        EstadisticasUtils.topNPartidas(partidas, AppConstants.maxPartidasTop, mejores: false);

    // Calculate moving average (expensive operation, cached here)
    final promedioMovil = EstadisticasUtils.promedioMovil(partidas, AppConstants.ventanaPromedioMovil);

    // Calcular estadísticas basadas en datos de pines (teclado visual)
    final promedioPrimerTiro = EstadisticasUtils.calcularPromedioPrimerTiro(partidas);
    final tasaConversionSpare = EstadisticasUtils.calcularTasaConversionSpare(partidas);

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
    };
  }

  /// Forzar recalculo de estadísticas
  void invalidateCache() {
    _cache = null;
    _lastUpdate = null;
    _lastSesionesCount = 0;
    _lastPartidasCount = 0;
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
