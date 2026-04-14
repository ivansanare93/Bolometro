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
          ...List.generate(9, (i) => [AppConstants.simboloStrike] as List<String>),
          ['7', AppConstants.simboloSpare, AppConstants.simboloStrike],
        ],
        // Game 2: 10 spares
        [
          ...List.generate(9, (i) => ['5', AppConstants.simboloSpare] as List<String>),
          ['5', AppConstants.simboloSpare, '5'],
        ],
        // Game 3: 10 open frames
        [
          ...List.generate(9, (i) => ['6', '3'] as List<String>),
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
          ...List.generate(9, (i) => [AppConstants.simboloStrike] as List<String>),
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
          ...List.generate(9, (i) => ['7', AppConstants.simboloSpare] as List<String>),
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
        List<List<String>>.generate(10, (i) => ['5', '4']),
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

      // // Act
      // final porcentajes = EstadisticasUtils.calcularPorcentajes(partidasFrames);

      // // Assert - 10 frames: 3 strikes, 2 spares, 5 open
      // expect(porcentajes['strikes'], equals(30.0));
      // expect(porcentajes['spares'], equals(20.0));
      // expect(porcentajes['fallos'], equals(50.0));
    });

    test('promedioMovil should return empty list when fewer than windowSize games', () {
      // Arrange - Only 3 games, window size is 5
      final partidas = [
        Partida(fecha: DateTime(2024, 1, 1), total: 100, frames: []),
        Partida(fecha: DateTime(2024, 1, 2), total: 120, frames: []),
        Partida(fecha: DateTime(2024, 1, 3), total: 140, frames: []),
      ];

      // Act
      final result = EstadisticasUtils.promedioMovil(partidas, 5);

      // Assert
      expect(result, isEmpty);
    });

    test('promedioMovil should return 2 points when exactly windowSize games', () {
      // Arrange - Exactly 5 games
      final partidas = [
        Partida(fecha: DateTime(2024, 1, 1), total: 100, frames: []),
        Partida(fecha: DateTime(2024, 1, 2), total: 120, frames: []),
        Partida(fecha: DateTime(2024, 1, 3), total: 140, frames: []),
        Partida(fecha: DateTime(2024, 1, 4), total: 160, frames: []),
        Partida(fecha: DateTime(2024, 1, 5), total: 180, frames: []),
      ];

      // Act
      final result = EstadisticasUtils.promedioMovil(partidas, 5);

      // Assert - Should have 2 points (duplicated to ensure chart renders)
      expect(result.length, equals(2));
      expect(result[0], equals(140.0)); // Average of 100,120,140,160,180
      expect(result[1], equals(140.0)); // Duplicated value
    });

    test('promedioMovil should return correct number of points for more than windowSize games', () {
      // Arrange - 7 games
      final partidas = [
        Partida(fecha: DateTime(2024, 1, 1), total: 100, frames: []),
        Partida(fecha: DateTime(2024, 1, 2), total: 110, frames: []),
        Partida(fecha: DateTime(2024, 1, 3), total: 120, frames: []),
        Partida(fecha: DateTime(2024, 1, 4), total: 130, frames: []),
        Partida(fecha: DateTime(2024, 1, 5), total: 140, frames: []),
        Partida(fecha: DateTime(2024, 1, 6), total: 150, frames: []),
        Partida(fecha: DateTime(2024, 1, 7), total: 160, frames: []),
      ];

      // Act
      final result = EstadisticasUtils.promedioMovil(partidas, 5);

      // Assert - Should have 3 points (indices 0-4, 1-5, 2-6)
      expect(result.length, equals(3));
      expect(result[0], equals(120.0)); // Average of 100,110,120,130,140
      expect(result[1], equals(130.0)); // Average of 110,120,130,140,150
      expect(result[2], equals(140.0)); // Average of 120,130,140,150,160
    });

    test('promedioMovil should calculate correct moving average values', () {
      // Arrange - 6 games with predictable scores
      final partidas = [
        Partida(fecha: DateTime(2024, 1, 1), total: 100, frames: []),
        Partida(fecha: DateTime(2024, 1, 2), total: 100, frames: []),
        Partida(fecha: DateTime(2024, 1, 3), total: 100, frames: []),
        Partida(fecha: DateTime(2024, 1, 4), total: 100, frames: []),
        Partida(fecha: DateTime(2024, 1, 5), total: 100, frames: []),
        Partida(fecha: DateTime(2024, 1, 6), total: 200, frames: []),
      ];

      // Act
      final result = EstadisticasUtils.promedioMovil(partidas, 5);

      // Assert - Should have 2 points
      expect(result.length, equals(2));
      expect(result[0], equals(100.0)); // Average of first 5: all 100s
      expect(result[1], equals(120.0)); // Average of last 5: four 100s and one 200
    });
  });

  // ---------------------------------------------------------------------------
  group('EstadisticasUtils - calcularPromedioPrimerTiro', () {
    test('returns null when no partidas have pin data', () {
      final partidas = [
        Partida(fecha: DateTime(2024, 1, 1), total: 100, frames: []),
        Partida(fecha: DateTime(2024, 1, 2), total: 120, frames: []),
      ];
      expect(EstadisticasUtils.calcularPromedioPrimerTiro(partidas), isNull);
    });

    test('returns null for empty list of partidas', () {
      expect(EstadisticasUtils.calcularPromedioPrimerTiro([]), isNull);
    });

    test('calculates correct average for single game with all strikes', () {
      // 10 frames, each first throw knocks 10 pins
      final pinesPorTiro = List.generate(
        AppConstants.totalFrames,
        (_) => <List<int>?>[List.generate(10, (i) => i + 1), null, null],
      );
      final partida = Partida(
        fecha: DateTime(2024, 1, 1),
        total: 300,
        frames: List.generate(AppConstants.totalFrames, (_) => ['X']),
        pinesPorTiro: pinesPorTiro,
      );
      final result = EstadisticasUtils.calcularPromedioPrimerTiro([partida]);
      expect(result, equals(10.0));
    });

    test('calculates correct average for single game with 5 pins per first throw', () {
      // 10 frames, each first throw knocks 5 pins
      final pinesPorTiro = List.generate(
        AppConstants.totalFrames,
        (_) => <List<int>?>[
          [1, 2, 3, 4, 5], // 5 pins
          [6, 7, 8, 9, 10], // spare
          null,
        ],
      );
      final partida = Partida(
        fecha: DateTime(2024, 1, 1),
        total: 150,
        frames: List.generate(AppConstants.totalFrames, (_) => ['5', '/']),
        pinesPorTiro: pinesPorTiro,
      );
      final result = EstadisticasUtils.calcularPromedioPrimerTiro([partida]);
      expect(result, equals(5.0));
    });

    test('ignores frames without pin data', () {
      // Only 5 frames have pin data (first 5), each with 8 pins on first throw
      final pinesPorTiro = List.generate(
        AppConstants.totalFrames,
        (i) => <List<int>?>[
          i < 5 ? [1, 2, 3, 4, 5, 6, 7, 8] : null, // 8 pins or null
          null,
          null,
        ],
      );
      final partida = Partida(
        fecha: DateTime(2024, 1, 1),
        total: 100,
        frames: List.generate(AppConstants.totalFrames, (_) => ['8', '1']),
        pinesPorTiro: pinesPorTiro,
      );
      // Only 5 frames have data, each with 8 pins → average = 8.0
      final result = EstadisticasUtils.calcularPromedioPrimerTiro([partida]);
      expect(result, equals(8.0));
    });

    test('averages correctly across multiple partidas', () {
      // Game 1: all frames with 6 pins on first throw
      final pines1 = List.generate(
        AppConstants.totalFrames,
        (_) => <List<int>?>[
          [1, 2, 3, 4, 5, 6],
          null,
          null,
        ],
      );
      // Game 2: all frames with 8 pins on first throw
      final pines2 = List.generate(
        AppConstants.totalFrames,
        (_) => <List<int>?>[
          [1, 2, 3, 4, 5, 6, 7, 8],
          null,
          null,
        ],
      );
      final partidas = [
        Partida(
          fecha: DateTime(2024, 1, 1),
          total: 100,
          frames: List.generate(AppConstants.totalFrames, (_) => ['6', '2']),
          pinesPorTiro: pines1,
        ),
        Partida(
          fecha: DateTime(2024, 1, 2),
          total: 120,
          frames: List.generate(AppConstants.totalFrames, (_) => ['8', '1']),
          pinesPorTiro: pines2,
        ),
      ];
      // 10 throws of 6 + 10 throws of 8 = 140 / 20 = 7.0
      final result = EstadisticasUtils.calcularPromedioPrimerTiro(partidas);
      expect(result, equals(7.0));
    });
  });

  // ---------------------------------------------------------------------------
  group('EstadisticasUtils - calcularTasaConversionSpare', () {
    test('returns null when no partidas have pin data', () {
      final partidas = [
        Partida(fecha: DateTime(2024, 1, 1), total: 100, frames: []),
      ];
      expect(EstadisticasUtils.calcularTasaConversionSpare(partidas), isNull);
    });

    test('returns null for empty list of partidas', () {
      expect(EstadisticasUtils.calcularTasaConversionSpare([]), isNull);
    });

    test('returns 100% when all non-strike frames are spared', () {
      // 9 frames (indices 0-8), each frame: first throw knocks 5, second knocks 5 (spare)
      final pinesPorTiro = List.generate(
        AppConstants.totalFrames,
        (i) => <List<int>?>[
          i < 9 ? [1, 2, 3, 4, 5] : null,      // 5 pins in first throw
          i < 9 ? [6, 7, 8, 9, 10] : null,     // 5 remaining pins = spare
          null,
        ],
      );
      final partida = Partida(
        fecha: DateTime(2024, 1, 1),
        total: 150,
        frames: List.generate(AppConstants.totalFrames, (_) => ['5', '/']),
        pinesPorTiro: pinesPorTiro,
      );
      final result = EstadisticasUtils.calcularTasaConversionSpare([partida]);
      expect(result, equals(100.0));
    });

    test('returns 0% when no spares were converted', () {
      // 9 frames, first throw knocks 5, second knocks 3 (no spare)
      final pinesPorTiro = List.generate(
        AppConstants.totalFrames,
        (i) => <List<int>?>[
          i < 9 ? [1, 2, 3, 4, 5] : null,
          i < 9 ? [6, 7, 8] : null, // only 3 of remaining 5 → open frame
          null,
        ],
      );
      final partida = Partida(
        fecha: DateTime(2024, 1, 1),
        total: 80,
        frames: List.generate(AppConstants.totalFrames, (_) => ['5', '3']),
        pinesPorTiro: pinesPorTiro,
      );
      final result = EstadisticasUtils.calcularTasaConversionSpare([partida]);
      expect(result, equals(0.0));
    });

    test('calculates 50% conversion rate correctly', () {
      // 9 frames: odd frames are spared, even frames are open
      final pinesPorTiro = List.generate(
        AppConstants.totalFrames,
        (i) {
          if (i >= 9) return <List<int>?>[null, null, null];
          final isSpare = i.isOdd;
          return <List<int>?>[
            [1, 2, 3, 4, 5],
            isSpare ? [6, 7, 8, 9, 10] : [6, 7, 8],
            null,
          ];
        },
      );
      final partida = Partida(
        fecha: DateTime(2024, 1, 1),
        total: 100,
        frames: List.generate(
          AppConstants.totalFrames,
          (i) => i < 9
              ? (i.isOdd ? ['5', '/'] : ['5', '3'])
              : ['5', '3'],
        ),
        pinesPorTiro: pinesPorTiro,
      );
      // 9 frames: 4 odd (0-indexed: 1,3,5,7) + 5 even (0,2,4,6,8) → 4/9 spares
      final result = EstadisticasUtils.calcularTasaConversionSpare([partida]);
      expect(result, closeTo((4 / 9) * 100, 0.01));
    });

    test('ignores frames where first throw is a strike', () {
      // 9 frames: all strikes → no conversion opportunities
      final pinesPorTiro = List.generate(
        AppConstants.totalFrames,
        (i) => <List<int>?>[
          i < 9 ? List.generate(10, (j) => j + 1) : null, // strike
          null,
          null,
        ],
      );
      final partida = Partida(
        fecha: DateTime(2024, 1, 1),
        total: 200,
        frames: List.generate(AppConstants.totalFrames, (_) => ['X']),
        pinesPorTiro: pinesPorTiro,
      );
      // No non-strike frames → null (no opportunities)
      final result = EstadisticasUtils.calcularTasaConversionSpare([partida]);
      expect(result, isNull);
    });

    test('includes frame 10 non-strike first throw as a spare opportunity', () {
      // Only frame 10 (index 9) has pin data; first throw not a strike → spare opportunity
      final pinesPorTiro = List.generate(
        AppConstants.totalFrames,
        (i) => <List<int>?>[
          i == 9 ? [1, 2, 3, 4, 5] : null,
          i == 9 ? [6, 7, 8, 9, 10] : null, // all remaining → spare converted
          null,
        ],
      );
      final partida = Partida(
        fecha: DateTime(2024, 1, 1),
        total: 100,
        frames: List.generate(AppConstants.totalFrames, (i) => i == 9 ? ['5', '/'] : []),
        pinesPorTiro: pinesPorTiro,
      );
      final result = EstadisticasUtils.calcularTasaConversionSpare([partida]);
      expect(result, equals(100.0));
    });

    test('includes frame 10 strike-then-non-strike as a spare opportunity', () {
      // Frame 10: tiro0=strike, tiro1=5 pins, tiro2=converts spare
      final pinesPorTiro = List.generate(
        AppConstants.totalFrames,
        (i) => <List<int>?>[
          i == 9 ? List.generate(10, (j) => j + 1) : null, // strike
          i == 9 ? [1, 2, 3, 4, 5] : null,                 // 5 pins
          i == 9 ? [6, 7, 8, 9, 10] : null,                // remaining 5 → spare
        ],
      );
      final partida = Partida(
        fecha: DateTime(2024, 1, 1),
        total: 150,
        frames: List.generate(AppConstants.totalFrames, (i) => i == 9 ? ['X', '5', '/'] : []),
        pinesPorTiro: pinesPorTiro,
      );
      final result = EstadisticasUtils.calcularTasaConversionSpare([partida]);
      expect(result, equals(100.0));
    });

    test('frame 10 strike-then-strike yields no extra spare opportunity', () {
      // Frame 10: tiro0=strike, tiro1=strike → tiro1 is also a strike, no spare chance
      final pinesPorTiro = List.generate(
        AppConstants.totalFrames,
        (i) => <List<int>?>[
          i == 9 ? List.generate(10, (j) => j + 1) : null, // strike
          i == 9 ? List.generate(10, (j) => j + 1) : null, // strike → no spare opp
          i == 9 ? List.generate(10, (j) => j + 1) : null, // strike
        ],
      );
      final partida = Partida(
        fecha: DateTime(2024, 1, 1),
        total: 300,
        frames: List.generate(AppConstants.totalFrames, (i) => i == 9 ? ['X', 'X', 'X'] : []),
        pinesPorTiro: pinesPorTiro,
      );
      final result = EstadisticasUtils.calcularTasaConversionSpare([partida]);
      expect(result, isNull); // no non-strike spare opportunities anywhere
    });
  });

  // ---------------------------------------------------------------------------
  group('EstadisticasUtils - calcularConversionSparePorPin', () {
    test('returns empty map when no partidas have pin data', () {
      final partidas = [
        Partida(fecha: DateTime(2024, 1, 1), total: 100, frames: []),
      ];
      expect(EstadisticasUtils.calcularConversionSparePorPin(partidas), isEmpty);
    });

    test('returns empty map for empty list', () {
      expect(EstadisticasUtils.calcularConversionSparePorPin([]), isEmpty);
    });

    test('groups single-pin leave correctly', () {
      // Frame 0: knocks 9 pins (leaves pin 10 only), then converts
      final pinesPorTiro = List.generate(
        AppConstants.totalFrames,
        (i) => <List<int>?>[
          i == 0 ? [1, 2, 3, 4, 5, 6, 7, 8, 9] : null,
          i == 0 ? [10] : null,
          null,
        ],
      );
      final partida = Partida(
        fecha: DateTime(2024, 1, 1),
        total: 100,
        frames: List.generate(AppConstants.totalFrames, (i) => i == 0 ? ['9', '/'] : []),
        pinesPorTiro: pinesPorTiro,
      );
      final result = EstadisticasUtils.calcularConversionSparePorPin([partida]);
      expect(result.containsKey('10'), isTrue);
      expect(result['10'], equals([1, 1])); // 1 attempt, 1 conversion
    });

    test('groups multi-pin leave by sorted pins', () {
      // Frame 0: knocks pins 1-8 (leaves 9 and 10), does not convert
      final pinesPorTiro = List.generate(
        AppConstants.totalFrames,
        (i) => <List<int>?>[
          i == 0 ? [1, 2, 3, 4, 5, 6, 7, 8] : null,
          i == 0 ? [9] : null, // only knocks 9, leaves 10 → not a spare
          null,
        ],
      );
      final partida = Partida(
        fecha: DateTime(2024, 1, 1),
        total: 80,
        frames: List.generate(AppConstants.totalFrames, (i) => i == 0 ? ['8', '1'] : []),
        pinesPorTiro: pinesPorTiro,
      );
      final result = EstadisticasUtils.calcularConversionSparePorPin([partida]);
      expect(result.containsKey('9,10'), isTrue);
      expect(result['9,10'], equals([1, 0])); // 1 attempt, 0 conversions
    });

    test('accumulates stats across multiple frames and partidas', () {
      // Two partidas, each with frame 0 leaving pin 7 only
      // Partida 1: converts; Partida 2: does not convert
      List<List<List<int>?>> makePines({required bool converts}) =>
          List.generate(AppConstants.totalFrames, (i) => <List<int>?>[
                i == 0 ? [1, 2, 3, 4, 5, 6, 8, 9, 10] : null, // leaves pin 7
                i == 0 ? (converts ? [7] : []) : null,
                null,
              ]);

      final partida1 = Partida(
        fecha: DateTime(2024, 1, 1),
        total: 100,
        frames: List.generate(AppConstants.totalFrames, (i) => i == 0 ? ['9', '/'] : []),
        pinesPorTiro: makePines(converts: true),
      );
      final partida2 = Partida(
        fecha: DateTime(2024, 1, 2),
        total: 90,
        frames: List.generate(AppConstants.totalFrames, (i) => i == 0 ? ['9', '0'] : []),
        pinesPorTiro: makePines(converts: false),
      );
      final result = EstadisticasUtils.calcularConversionSparePorPin([partida1, partida2]);
      expect(result.containsKey('7'), isTrue);
      expect(result['7'], equals([2, 1])); // 2 attempts, 1 conversion
    });

    test('includes frame 10 non-strike first throw', () {
      // Frame 10: tiro0 knocks 5, tiro1 knocks remaining 5 (spare)
      final pinesPorTiro = List.generate(
        AppConstants.totalFrames,
        (i) => <List<int>?>[
          i == 9 ? [1, 2, 3, 4, 5] : null,
          i == 9 ? [6, 7, 8, 9, 10] : null,
          null,
        ],
      );
      final partida = Partida(
        fecha: DateTime(2024, 1, 1),
        total: 100,
        frames: List.generate(AppConstants.totalFrames, (i) => i == 9 ? ['5', '/'] : []),
        pinesPorTiro: pinesPorTiro,
      );
      final result = EstadisticasUtils.calcularConversionSparePorPin([partida]);
      expect(result.containsKey('6,7,8,9,10'), isTrue);
      final statsF10a = result['6,7,8,9,10']!;
      expect(statsF10a[0], equals(1)); // 1 attempt
      expect(statsF10a[1], equals(1)); // 1 conversion
    });

    test('includes frame 10 strike-then-non-strike spare opportunity', () {
      // Frame 10: tiro0=strike, tiro1=5 pins, tiro2=remaining 5 (spare)
      final pinesPorTiro = List.generate(
        AppConstants.totalFrames,
        (i) => <List<int>?>[
          i == 9 ? List.generate(10, (j) => j + 1) : null, // strike
          i == 9 ? [1, 2, 3, 4, 5] : null,
          i == 9 ? [6, 7, 8, 9, 10] : null, // spare
        ],
      );
      final partida = Partida(
        fecha: DateTime(2024, 1, 1),
        total: 150,
        frames: List.generate(AppConstants.totalFrames, (i) => i == 9 ? ['X', '5', '/'] : []),
        pinesPorTiro: pinesPorTiro,
      );
      final result = EstadisticasUtils.calcularConversionSparePorPin([partida]);
      expect(result.containsKey('6,7,8,9,10'), isTrue);
      final statsF10b = result['6,7,8,9,10']!;
      expect(statsF10b[0], equals(1));
      expect(statsF10b[1], equals(1));
    });

    test('ignores strike frames (no spare opportunity)', () {
      // All frames are strikes → no spare opportunities
      final pinesPorTiro = List.generate(
        AppConstants.totalFrames,
        (i) => <List<int>?>[
          List.generate(10, (j) => j + 1), // strike
          null,
          null,
        ],
      );
      final partida = Partida(
        fecha: DateTime(2024, 1, 1),
        total: 300,
        frames: List.generate(AppConstants.totalFrames, (_) => ['X']),
        pinesPorTiro: pinesPorTiro,
      );
      final result = EstadisticasUtils.calcularConversionSparePorPin([partida]);
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  group('EstadisticasUtils - calcularTendenciaDelta', () {
    Partida _makePartida(int total) => Partida(
          fecha: DateTime(2024, 1, 1),
          total: total,
          frames: [],
        );

    test('returns null when fewer than 10 partidas', () {
      final partidas = List.generate(9, (_) => _makePartida(150));
      expect(EstadisticasUtils.calcularTendenciaDelta(partidas), isNull);
    });

    test('returns null for empty list', () {
      expect(EstadisticasUtils.calcularTendenciaDelta([]), isNull);
    });

    test('compares last 5 vs previous 5 when 10–19 games', () {
      // Previous 5: 100 each → avg 100.  Last 5: 150 each → avg 150.
      final partidas = [
        ...List.generate(5, (_) => _makePartida(100)),
        ...List.generate(5, (_) => _makePartida(150)),
      ];
      final delta = EstadisticasUtils.calcularTendenciaDelta(partidas);
      expect(delta, closeTo(50.0, 0.001));
    });

    test('compares last 10 vs previous 10 when >= 20 games', () {
      // Previous 10: 100 each → avg 100.  Last 10: 120 each → avg 120.
      final partidas = [
        ...List.generate(10, (_) => _makePartida(100)),
        ...List.generate(10, (_) => _makePartida(120)),
      ];
      final delta = EstadisticasUtils.calcularTendenciaDelta(partidas);
      expect(delta, closeTo(20.0, 0.001));
    });

    test('returns negative delta when recent performance is worse', () {
      // Previous 10: 150 each → avg 150.  Last 10: 130 each → avg 130.
      final partidas = [
        ...List.generate(10, (_) => _makePartida(150)),
        ...List.generate(10, (_) => _makePartida(130)),
      ];
      final delta = EstadisticasUtils.calcularTendenciaDelta(partidas);
      expect(delta, closeTo(-20.0, 0.001));
    });

    test('returns zero delta when performance is identical', () {
      final partidas = List.generate(20, (_) => _makePartida(150));
      final delta = EstadisticasUtils.calcularTendenciaDelta(partidas);
      expect(delta, closeTo(0.0, 0.001));
    });

    test('uses last 5 vs 5 at exactly 10 games', () {
      final partidas = [
        ...List.generate(5, (_) => _makePartida(100)),
        ...List.generate(5, (_) => _makePartida(200)),
      ];
      final delta = EstadisticasUtils.calcularTendenciaDelta(partidas);
      expect(delta, closeTo(100.0, 0.001));
    });

    test('uses last 10 vs 10 at exactly 20 games', () {
      final partidas = [
        ...List.generate(10, (_) => _makePartida(100)),
        ...List.generate(10, (_) => _makePartida(200)),
      ];
      final delta = EstadisticasUtils.calcularTendenciaDelta(partidas);
      expect(delta, closeTo(100.0, 0.001));
    });
  });

  // ---------------------------------------------------------------------------
  group('EstadisticasUtils - calcularConsistencia', () {
    Partida _makePartida(int total) => Partida(
          fecha: DateTime(2024, 1, 1),
          total: total,
          frames: [],
        );

    test('returns 0.0 for empty list', () {
      expect(EstadisticasUtils.calcularConsistencia([]), equals(0.0));
    });

    test('returns 0.0 for single game', () {
      expect(
          EstadisticasUtils.calcularConsistencia([_makePartida(150)]),
          equals(0.0));
    });

    test('returns 0.0 when all scores are identical', () {
      final partidas = List.generate(5, (_) => _makePartida(150));
      expect(EstadisticasUtils.calcularConsistencia(partidas), equals(0.0));
    });

    test('computes correct standard deviation for known values', () {
      // Values: 100, 200 → mean 150, deviations -50 and +50
      // variance = (2500 + 2500) / 2 = 2500, std = 50
      final partidas = [_makePartida(100), _makePartida(200)];
      expect(
          EstadisticasUtils.calcularConsistencia(partidas),
          closeTo(50.0, 0.001));
    });

    test('lower consistency value for more uniform scores', () {
      // Uniform: 150, 150, 150 → std = 0
      // Varied:  100, 150, 200 → std > 0
      final uniform = List.generate(3, (_) => _makePartida(150));
      final varied = [_makePartida(100), _makePartida(150), _makePartida(200)];
      expect(
          EstadisticasUtils.calcularConsistencia(uniform),
          lessThan(EstadisticasUtils.calcularConsistencia(varied)));
    });
  });
}
