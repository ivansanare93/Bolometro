import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/models/bowling_ball.dart';

/// Tests for the BowlingBall and BallMaintenance models.
void main() {
  group('BowlingBall Model', () {
    test('creates with default values and generated id', () {
      final bola = BowlingBall(name: 'Storm Phaze II', weightLbs: 15);

      expect(bola.name, equals('Storm Phaze II'));
      expect(bola.weightLbs, equals(15));
      expect(bola.isActive, isTrue);
      expect(bola.id, isNotEmpty);
    });

    test('copyWith preserves id and updates fields', () {
      final bola = BowlingBall(name: 'Bola A', weightLbs: 14, brand: 'Storm');
      final actualizada = bola.copyWith(name: 'Bola B', isActive: false);

      expect(actualizada.id, equals(bola.id));
      expect(actualizada.name, equals('Bola B'));
      expect(actualizada.brand, equals('Storm'));
      expect(actualizada.isActive, isFalse);
    });

    test('toJson/fromJson round trip preserves data', () {
      final bola = BowlingBall(
        name: 'Bola Test',
        brand: 'Hammer',
        weightLbs: 16,
        coverstock: 'Reactive',
        finish: '1500 grit',
        purchaseDate: DateTime(2023, 5, 1),
        notes: 'Bola de spare',
      );

      final json = bola.toJson();
      final reconstruida = BowlingBall.fromJson(json);

      expect(reconstruida.id, equals(bola.id));
      expect(reconstruida.name, equals(bola.name));
      expect(reconstruida.brand, equals(bola.brand));
      expect(reconstruida.weightLbs, equals(bola.weightLbs));
      expect(reconstruida.coverstock, equals(bola.coverstock));
      expect(reconstruida.finish, equals(bola.finish));
      expect(reconstruida.purchaseDate, equals(bola.purchaseDate));
      expect(reconstruida.notes, equals(bola.notes));
    });

    test('two balls created without explicit id get different ids', () {
      final a = BowlingBall(name: 'A', weightLbs: 14);
      final b = BowlingBall(name: 'B', weightLbs: 14);
      expect(a.id, isNot(equals(b.id)));
    });
  });

  group('BallMaintenance Model', () {
    test('normalizes an unknown type to "other"', () {
      final m = BallMaintenance(ballId: 'bola1', type: 'invalid-type');
      expect(m.type, equals(BallMaintenanceType.other));
    });

    test('keeps a valid type', () {
      final m = BallMaintenance(
        ballId: 'bola1',
        type: BallMaintenanceType.resurfacing,
      );
      expect(m.type, equals(BallMaintenanceType.resurfacing));
    });

    test('toJson/fromJson round trip preserves data', () {
      final m = BallMaintenance(
        ballId: 'bola1',
        type: BallMaintenanceType.cleaning,
        date: DateTime(2024, 3, 10),
        notes: 'Limpieza tras torneo',
      );

      final json = m.toJson();
      final reconstruido = BallMaintenance.fromJson(json);

      expect(reconstruido.id, equals(m.id));
      expect(reconstruido.ballId, equals(m.ballId));
      expect(reconstruido.type, equals(m.type));
      expect(reconstruido.date, equals(m.date));
      expect(reconstruido.notes, equals(m.notes));
    });
  });
}
