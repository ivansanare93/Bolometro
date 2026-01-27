import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/utils/app_constants.dart';

/// Tests for Partida model
void main() {
  group('Partida Model', () {
    test('Partida should be created with correct values', () {
      // Arrange
      final frames = List.generate(
        AppConstants.totalFrames,
        (i) => i < 9 ? [AppConstants.simboloStrike] : [AppConstants.simboloStrike, AppConstants.simboloStrike],
      );

      // Act
      final partida = Partida(
        total: 300,
        frames: frames,
        fecha: DateTime(2024, 1, 1),
        lugar: 'Test Bowling',
        notas: 'Perfect game',
      );

      // Assert
      expect(partida.total, equals(300));
      expect(partida.frames.length, equals(AppConstants.totalFrames));
      expect(partida.fecha, equals(DateTime(2024, 1, 1)));
      expect(partida.lugar, equals('Test Bowling'));
      expect(partida.notas, equals('Perfect game'));
    });

    test('Partida should handle strikes correctly', () {
      final frames = List.generate(
        AppConstants.totalFrames,
        (i) => [AppConstants.simboloStrike],
      );

      final partida = Partida(total: 300, frames: frames);

      expect(partida.frames[0][0], equals(AppConstants.simboloStrike));
      expect(partida.total, equals(300));
    });

    test('Partida should handle spares correctly', () {
      final frames = List.generate(
        AppConstants.totalFrames,
        (i) => ['5', AppConstants.simboloSpare],
      );

      final partida = Partida(total: 150, frames: frames);

      expect(partida.frames[0][1], equals(AppConstants.simboloSpare));
    });

    test('Partida with minimal data should work', () {
      final frames = List.generate(AppConstants.totalFrames, (i) => ['0', '0']);
      final partida = Partida(total: 0, frames: frames);

      expect(partida.total, equals(0));
      expect(partida.fecha, isNull);
      expect(partida.lugar, isNull);
      expect(partida.notas, isNull);
    });
  });
}
