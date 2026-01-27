import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/widgets/mapa_calor.dart';
import 'package:bolometro/utils/app_constants.dart';

/// Tests for mapa_calor functions
void main() {
  group('contarPartidasPorDia', () {
    test('should count partidas correctly when partida.fecha is null', () {
      // Arrange
      final sesionFecha = DateTime(2024, 1, 15);
      final partida1 = Partida(
        total: 150,
        frames: List.generate(AppConstants.totalFrames, (i) => ['5', '5']),
        fecha: null, // No specific fecha for this partida
      );
      final partida2 = Partida(
        total: 180,
        frames: List.generate(AppConstants.totalFrames, (i) => [AppConstants.simboloStrike]),
        fecha: null, // No specific fecha for this partida
      );

      final sesion = Sesion(
        fecha: sesionFecha,
        lugar: 'Test Bowling',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [partida1, partida2],
      );

      // Act
      final result = contarPartidasPorDia([sesion]);

      // Assert
      final expectedDate = DateTime(2024, 1, 15);
      expect(result.containsKey(expectedDate), isTrue);
      expect(result[expectedDate], equals(2));
    });

    test('should count partidas correctly when partida.fecha is set', () {
      // Arrange
      final sesionFecha = DateTime(2024, 1, 15);
      final partidaFecha1 = DateTime(2024, 1, 16, 10, 30); // Different date with time
      final partidaFecha2 = DateTime(2024, 1, 16, 14, 45); // Same day, different time
      
      final partida1 = Partida(
        total: 150,
        frames: List.generate(AppConstants.totalFrames, (i) => ['5', '5']),
        fecha: partidaFecha1,
      );
      final partida2 = Partida(
        total: 180,
        frames: List.generate(AppConstants.totalFrames, (i) => [AppConstants.simboloStrike]),
        fecha: partidaFecha2,
      );

      final sesion = Sesion(
        fecha: sesionFecha,
        lugar: 'Test Bowling',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [partida1, partida2],
      );

      // Act
      final result = contarPartidasPorDia([sesion]);

      // Assert
      final expectedDate = DateTime(2024, 1, 16);
      expect(result.containsKey(expectedDate), isTrue);
      expect(result[expectedDate], equals(2));
      // Session date should not have any partidas since both have explicit dates
      expect(result.containsKey(DateTime(2024, 1, 15)), isFalse);
    });

    test('should count partidas correctly with mixed null and non-null fechas', () {
      // Arrange
      final sesionFecha = DateTime(2024, 1, 15);
      final partidaConFecha = Partida(
        total: 150,
        frames: List.generate(AppConstants.totalFrames, (i) => ['5', '5']),
        fecha: DateTime(2024, 1, 16, 10, 30),
      );
      final partidaSinFecha = Partida(
        total: 180,
        frames: List.generate(AppConstants.totalFrames, (i) => [AppConstants.simboloStrike]),
        fecha: null,
      );

      final sesion = Sesion(
        fecha: sesionFecha,
        lugar: 'Test Bowling',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [partidaConFecha, partidaSinFecha],
      );

      // Act
      final result = contarPartidasPorDia([sesion]);

      // Assert
      expect(result.containsKey(DateTime(2024, 1, 15)), isTrue);
      expect(result[DateTime(2024, 1, 15)], equals(1)); // partidaSinFecha uses sesion.fecha
      expect(result.containsKey(DateTime(2024, 1, 16)), isTrue);
      expect(result[DateTime(2024, 1, 16)], equals(1)); // partidaConFecha uses its own fecha
    });

    test('should handle multiple sesiones', () {
      // Arrange
      final sesion1 = Sesion(
        fecha: DateTime(2024, 1, 15),
        lugar: 'Bowling A',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [
          Partida(
            total: 150,
            frames: List.generate(AppConstants.totalFrames, (i) => ['5', '5']),
          ),
        ],
      );

      final sesion2 = Sesion(
        fecha: DateTime(2024, 1, 15),
        lugar: 'Bowling B',
        tipo: AppConstants.tipoCompeticion,
        partidas: [
          Partida(
            total: 180,
            frames: List.generate(AppConstants.totalFrames, (i) => [AppConstants.simboloStrike]),
          ),
        ],
      );

      // Act
      final result = contarPartidasPorDia([sesion1, sesion2]);

      // Assert
      final expectedDate = DateTime(2024, 1, 15);
      expect(result.containsKey(expectedDate), isTrue);
      expect(result[expectedDate], equals(2)); // Both partidas on same day
    });

    test('should handle empty sesiones list', () {
      // Act
      final result = contarPartidasPorDia([]);

      // Assert
      expect(result.isEmpty, isTrue);
    });

    test('should handle sesion with no partidas', () {
      // Arrange
      final sesion = Sesion(
        fecha: DateTime(2024, 1, 15),
        lugar: 'Test Bowling',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [],
      );

      // Act
      final result = contarPartidasPorDia([sesion]);

      // Assert
      expect(result.isEmpty, isTrue);
    });

    test('should normalize dates to day-only (ignoring time)', () {
      // Arrange
      final partida = Partida(
        total: 150,
        frames: List.generate(AppConstants.totalFrames, (i) => ['5', '5']),
        fecha: DateTime(2024, 1, 15, 14, 30, 45), // With time components
      );

      final sesion = Sesion(
        fecha: DateTime(2024, 1, 10),
        lugar: 'Test Bowling',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [partida],
      );

      // Act
      final result = contarPartidasPorDia([sesion]);

      // Assert
      final expectedDate = DateTime(2024, 1, 15); // No time components
      expect(result.containsKey(expectedDate), isTrue);
      expect(result[expectedDate], equals(1));
    });
  });
}
