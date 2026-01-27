import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/utils/app_constants.dart';

/// Tests for Sesion model
void main() {
  group('Sesion Model', () {
    test('Sesion should be created with correct values', () {
      // Arrange
      final partidas = [
        Partida(
          total: 150,
          frames: List.generate(AppConstants.totalFrames, (i) => ['5', AppConstants.simboloSpare]),
        ),
        Partida(
          total: 180,
          frames: List.generate(AppConstants.totalFrames, (i) => [AppConstants.simboloStrike]),
        ),
      ];

      // Act
      final sesion = Sesion(
        fecha: DateTime(2024, 1, 1),
        lugar: 'Test Bowling Center',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: partidas,
        notas: 'Good practice session',
      );

      // Assert
      expect(sesion.fecha, equals(DateTime(2024, 1, 1)));
      expect(sesion.lugar, equals('Test Bowling Center'));
      expect(sesion.tipo, equals(AppConstants.tipoEntrenamiento));
      expect(sesion.partidas.length, equals(2));
      expect(sesion.notas, equals('Good practice session'));
    });

    test('Sesion with single partida should work', () {
      final partida = Partida(
        total: 150,
        frames: List.generate(AppConstants.totalFrames, (i) => ['5', '5']),
      );

      final sesion = Sesion(
        fecha: DateTime.now(),
        lugar: 'Test',
        tipo: AppConstants.tipoCompeticion,
        partidas: [partida],
      );

      expect(sesion.partidas.length, equals(1));
      expect(sesion.partidas.first.total, equals(150));
    });

    test('Sesion should handle multiple game types', () {
      final partida = Partida(
        total: 100,
        frames: List.generate(AppConstants.totalFrames, (i) => ['5', '4']),
      );

      final sesionEntrenamiento = Sesion(
        fecha: DateTime.now(),
        lugar: 'Test',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [partida],
      );

      final sesionCompeticion = Sesion(
        fecha: DateTime.now(),
        lugar: 'Test',
        tipo: AppConstants.tipoCompeticion,
        partidas: [partida],
      );

      expect(sesionEntrenamiento.tipo, equals(AppConstants.tipoEntrenamiento));
      expect(sesionCompeticion.tipo, equals(AppConstants.tipoCompeticion));
    });

    test('Sesion with empty partidas list should work', () {
      final sesion = Sesion(
        fecha: DateTime.now(),
        lugar: 'Test',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [],
      );

      expect(sesion.partidas.isEmpty, isTrue);
    });
  });
}
