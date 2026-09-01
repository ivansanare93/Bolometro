import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/services/ball_stats_service.dart';
import 'package:bolometro/utils/app_constants.dart';

Partida _partida(int total, {List<List<String>>? frames}) {
  return Partida(
    total: total,
    frames: frames ??
        List.generate(AppConstants.totalFrames, (_) => [AppConstants.simboloFallo]),
    ballId: 'bola1',
  );
}

/// Tests for the GetStatsByBall use case (BallStatsService).
void main() {
  group('BallStatsService', () {
    test('returns empty stats when there are no games', () {
      final stats = BallStatsService.calcular([]);

      expect(stats.partidasJugadas, equals(0));
      expect(stats.promedio, equals(0));
      expect(stats.mejorPartida, equals(0));
      expect(stats.strikeRate, equals(0));
      expect(stats.tendencia, equals(0));
    });

    test('computes games played, average and best game', () {
      final partidas = [_partida(150), _partida(200), _partida(180)];

      final stats = BallStatsService.calcular(partidas);

      expect(stats.partidasJugadas, equals(3));
      expect(stats.promedio, closeTo(176.67, 0.01));
      expect(stats.mejorPartida, equals(200));
    });

    test('computes strike rate from frames data', () {
      final framesTodosStrikes = List.generate(
        AppConstants.totalFrames,
        (_) => [AppConstants.simboloStrike],
      );
      final partidas = [_partida(300, frames: framesTodosStrikes)];

      final stats = BallStatsService.calcular(partidas);

      expect(stats.strikeRate, equals(100));
    });

    test('tendencia is zero with 5 games or fewer', () {
      final partidas = List.generate(5, (i) => _partida(150 + i));
      final stats = BallStatsService.calcular(partidas);
      expect(stats.tendencia, equals(0));
    });

    test('tendencia reflects improvement across recent games', () {
      // 6 partidas antiguas de 100, luego 5 recientes de 200 -> mejora
      final antiguas = List.generate(6, (_) => _partida(100));
      final recientes = List.generate(5, (_) => _partida(200));
      final stats = BallStatsService.calcular([...antiguas, ...recientes]);

      expect(stats.tendencia, greaterThan(0));
    });
  });
}
