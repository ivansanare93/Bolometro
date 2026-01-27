import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/utils/estadisticas_utils.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/utils/app_constants.dart';

/// Tests for EstadisticasUtils
void main() {
  group('EstadisticasUtils', () {
    late List<Sesion> sesionesTest;

    setUp(() {
      // Create test data
      sesionesTest = [
        Sesion(
          fecha: DateTime(2024, 1, 1),
          lugar: 'Test Bowling',
          tipo: AppConstants.tipoEntrenamiento,
          partidas: [
            Partida(
              fecha: DateTime(2024, 1, 1),
              total: 150,
              frames: List.generate(
                AppConstants.totalFrames,
                (i) => ['5', AppConstants.simboloSpare],
              ),
            ),
            Partida(
              fecha: DateTime(2024, 1, 1),
              total: 180,
              frames: List.generate(
                AppConstants.totalFrames,
                (i) => i < 9 ? [AppConstants.simboloStrike] : [AppConstants.simboloStrike, AppConstants.simboloStrike],
              ),
            ),
          ],
        ),
        Sesion(
          fecha: DateTime(2024, 1, 2),
          lugar: 'Test Bowling',
          tipo: AppConstants.tipoCompeticion,
          partidas: [
            Partida(
              fecha: DateTime(2024, 1, 2),
              total: 120,
              frames: List.generate(
                AppConstants.totalFrames,
                (i) => ['6', '3'],
              ),
            ),
          ],
        ),
      ];
    });

    test('calcularEstadisticas should return correct total sessions', () {
      // Act
      final stats = EstadisticasUtils.calcularEstadisticas(sesionesTest);

      // Assert
      expect(stats['totalSesiones'], equals(2));
    });

    test('calcularEstadisticas should return correct total games', () {
      // Act
      final stats = EstadisticasUtils.calcularEstadisticas(sesionesTest);

      // Assert
      expect(stats['totalPartidas'], equals(3));
    });

    test('calcularEstadisticas should calculate correct average', () {
      // Act
      final stats = EstadisticasUtils.calcularEstadisticas(sesionesTest);

      // Assert
      // Average of 150, 180, 120 = 450 / 3 = 150
      expect(stats['promedio'], equals(150.0));
    });

    test('calcularEstadisticas should find best game', () {
      // Act
      final stats = EstadisticasUtils.calcularEstadisticas(sesionesTest);

      // Assert
      expect(stats['mejorPartida'], equals(180));
    });

    test('calcularEstadisticas should handle empty sessions', () {
      // Act
      final stats = EstadisticasUtils.calcularEstadisticas([]);

      // Assert
      expect(stats['totalSesiones'], equals(0));
      expect(stats['totalPartidas'], equals(0));
      expect(stats['promedio'], equals(0.0));
      expect(stats['mejorPartida'], equals(0));
    });

    test('calcularEstadisticas should handle sessions with no games', () {
      // Arrange
      final emptySessionList = [
        Sesion(
          fecha: DateTime.now(),
          lugar: 'Test',
          tipo: AppConstants.tipoEntrenamiento,
          partidas: [],
        ),
      ];

      // Act
      final stats = EstadisticasUtils.calcularEstadisticas(emptySessionList);

      // Assert
      expect(stats['totalSesiones'], equals(1));
      expect(stats['totalPartidas'], equals(0));
    });

    test('calcularEstadisticas should filter by session type', () {
      // Act - filter only training sessions
      final trainingOnly = sesionesTest.where(
        (s) => s.tipo == AppConstants.tipoEntrenamiento,
      ).toList();
      
      final stats = EstadisticasUtils.calcularEstadisticas(trainingOnly);

      // Assert
      expect(stats['totalSesiones'], equals(1));
      expect(stats['totalPartidas'], equals(2));
    });

    test('calcularDistribucionPuntajes should create distribution', () {
      // Act
      final distribution = EstadisticasUtils.calcularDistribucionPuntajes(sesionesTest);

      // Assert
      expect(distribution, isNotEmpty);
      expect(distribution, isA<Map<String, int>>());
    });

    test('partidas should be sortable by score', () {
      // Arrange
      final partidas = sesionesTest.expand((s) => s.partidas).toList();

      // Act
      partidas.sort((a, b) => b.total.compareTo(a.total));

      // Assert
      expect(partidas.first.total, equals(180));
      expect(partidas.last.total, equals(120));
    });

    test('calcularPorcentajes should correctly calculate percentages', () {
      // Arrange - Create test data with known frame outcomes
      final partidasFrames = [
        // Game 1: 9 strikes + 1 spare in 10th frame (10 frames total)
        [
          ...List.generate(9, (i) => [AppConstants.simboloStrike]),
          ['7', AppConstants.simboloSpare, AppConstants.simboloStrike],
        ],
        // Game 2: 10 spares
        [
          ...List.generate(9, (i) => ['5', AppConstants.simboloSpare]),
          ['5', AppConstants.simboloSpare, '5'],
        ],
        // Game 3: 10 open frames
        [
          ...List.generate(9, (i) => ['6', '3']),
          ['6', '3'], // 10th frame with open frame (no bonus)
        ],
      ];

      // Act
      final porcentajes = EstadisticasUtils.calcularPorcentajes(partidasFrames);

      // Assert - 30 frames total: 9 strikes, 11 spares, 10 open
      expect(porcentajes['strikes'], closeTo(30.0, 0.1));
      expect(porcentajes['spares'], closeTo(36.67, 0.1));
      expect(porcentajes['fallos'], closeTo(33.33, 0.1));
    });

    test('calcularPorcentajes should handle all strikes', () {
      // Arrange - Realistic perfect game with 10th frame bonus balls
      final partidasFrames = [
        [
          // Frames 1-9: single strikes
          ...List.generate(9, (i) => [AppConstants.simboloStrike]),
          // Frame 10: strike with two bonus strikes
          [AppConstants.simboloStrike, AppConstants.simboloStrike, AppConstants.simboloStrike],
        ],
      ];

      // Act
      final porcentajes = EstadisticasUtils.calcularPorcentajes(partidasFrames);

      // Assert - Still 10 frames total, all are strikes
      expect(porcentajes['strikes'], equals(100.0));
      expect(porcentajes['spares'], equals(0.0));
      expect(porcentajes['fallos'], equals(0.0));
    });

    test('calcularPorcentajes should handle all spares', () {
      // Arrange - Realistic all spares game with 10th frame bonus ball
      final partidasFrames = [
        [
          // Frames 1-9: spares
          ...List.generate(9, (i) => ['7', AppConstants.simboloSpare]),
          // Frame 10: spare with bonus strike
          ['7', AppConstants.simboloSpare, AppConstants.simboloStrike],
        ],
      ];

      // Act
      final porcentajes = EstadisticasUtils.calcularPorcentajes(partidasFrames);

      // Assert - Still 10 frames total, all are spares
      expect(porcentajes['strikes'], equals(0.0));
      expect(porcentajes['spares'], equals(100.0));
      expect(porcentajes['fallos'], equals(0.0));
    });

    test('calcularPorcentajes should handle all open frames', () {
      // Arrange
      final partidasFrames = [
        List.generate(10, (i) => ['5', '4']),
      ];

      // Act
      final porcentajes = EstadisticasUtils.calcularPorcentajes(partidasFrames);

      // Assert
      expect(porcentajes['strikes'], equals(0.0));
      expect(porcentajes['spares'], equals(0.0));
      expect(porcentajes['fallos'], equals(100.0));
    });

    test('calcularPorcentajes should handle empty frames', () {
      // Arrange
      final partidasFrames = [
        <List<String>>[],
      ];

      // Act
      final porcentajes = EstadisticasUtils.calcularPorcentajes(partidasFrames);

      // Assert
      expect(porcentajes['strikes'], equals(0.0));
      expect(porcentajes['spares'], equals(0.0));
      expect(porcentajes['fallos'], equals(0.0));
    });

    test('calcularPorcentajes should skip empty frames in mixed data', () {
      // Arrange - 3 strikes, 2 spares, 5 open frames
      final partidasFrames = [
        [
          [AppConstants.simboloStrike],
          [AppConstants.simboloStrike],
          [AppConstants.simboloStrike],
          ['5', AppConstants.simboloSpare],
          ['7', AppConstants.simboloSpare],
          ['3', '4'],
          ['2', '5'],
          ['6', '1'],
          ['8', '0'],
          ['9', AppConstants.simboloFallo],
          [], // empty frame should be skipped
        ],
      ];

      // Act
      final porcentajes = EstadisticasUtils.calcularPorcentajes(partidasFrames);

      // Assert - 10 frames: 3 strikes, 2 spares, 5 open
      expect(porcentajes['strikes'], equals(30.0));
      expect(porcentajes['spares'], equals(20.0));
      expect(porcentajes['fallos'], equals(50.0));
    });
  });
}
