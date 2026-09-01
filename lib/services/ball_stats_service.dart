import '../models/partida.dart';
import '../utils/app_constants.dart';
import '../utils/estadisticas_utils.dart';

/// Estadísticas agregadas de una bola concreta, calculadas a partir de las
/// partidas en las que fue utilizada ([Partida.ballId]).
class EstadisticasBola {
  final int partidasJugadas;
  final double promedio;
  final int mejorPartida;
  final double strikeRate;
  final double tendencia; // diferencia entre el promedio reciente y el previo

  const EstadisticasBola({
    required this.partidasJugadas,
    required this.promedio,
    required this.mejorPartida,
    required this.strikeRate,
    required this.tendencia,
  });

  factory EstadisticasBola.vacia() => const EstadisticasBola(
        partidasJugadas: 0,
        promedio: 0,
        mejorPartida: 0,
        strikeRate: 0,
        tendencia: 0,
      );
}

/// Caso de uso: calcular estadísticas de rendimiento asociadas a una bola
/// concreta ("GetStatsByBall"). Recibe las partidas ya filtradas por bola
/// (ver [DataRepository.obtenerPartidasPorBola]), ordenadas cronológicamente.
class BallStatsService {
  static EstadisticasBola calcular(List<Partida> partidas) {
    if (partidas.isEmpty) return EstadisticasBola.vacia();

    final totales = partidas.map((p) => p.total).toList();
    final promedio = totales.reduce((a, b) => a + b) / totales.length;
    final mejorPartida = totales.reduce((a, b) => a > b ? a : b);

    final porcentajes = EstadisticasUtils.calcularPorcentajes(
      partidas.map((p) => p.frames).toList(),
    );
    final strikeRate = porcentajes['strikes'] ?? 0;

    // Tendencia: compara el promedio de las últimas partidas con el de las
    // anteriores a esas, usando la misma ventana definida para el resto de
    // la app.
    const ventana = AppConstants.ventanaPromedioMovil;
    double tendencia = 0;
    if (partidas.length > ventana) {
      final recientes = totales.sublist(totales.length - ventana);
      final anteriores = totales.sublist(0, totales.length - ventana);
      final promedioReciente =
          recientes.reduce((a, b) => a + b) / recientes.length;
      final promedioAnterior =
          anteriores.reduce((a, b) => a + b) / anteriores.length;
      tendencia = promedioReciente - promedioAnterior;
    }

    return EstadisticasBola(
      partidasJugadas: partidas.length,
      promedio: promedio,
      mejorPartida: mejorPartida,
      strikeRate: strikeRate,
      tendencia: tendencia,
    );
  }
}
