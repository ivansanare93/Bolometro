import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bolometro/services/temporada_service.dart';
import 'package:bolometro/utils/app_constants.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TemporadaService - getTemporadas', () {
    test('returns empty list when no seasons are stored', () async {
      final result = await TemporadaService.getTemporadas();
      expect(result, isEmpty);
    });

    test('returns saved list after addTemporada', () async {
      await TemporadaService.addTemporada('2025-2026');
      await TemporadaService.addTemporada('2024-2025');
      final result = await TemporadaService.getTemporadas();
      expect(result, contains('2025-2026'));
      expect(result, contains('2024-2025'));
    });
  });

  group('TemporadaService - addTemporada', () {
    test('adds a new season and returns true', () async {
      final ok = await TemporadaService.addTemporada('Liga 2026');
      expect(ok, isTrue);
      expect(await TemporadaService.getTemporadas(), contains('Liga 2026'));
    });

    test('trims whitespace from season name', () async {
      await TemporadaService.addTemporada('  2025  ');
      final result = await TemporadaService.getTemporadas();
      expect(result, contains('2025'));
      expect(result, isNot(contains('  2025  ')));
    });

    test('returns false for duplicate name', () async {
      await TemporadaService.addTemporada('2025');
      final ok = await TemporadaService.addTemporada('2025');
      expect(ok, isFalse);
      final result = await TemporadaService.getTemporadas();
      expect(result.where((e) => e == '2025').length, equals(1));
    });

    test('returns false for empty name', () async {
      final ok = await TemporadaService.addTemporada('');
      expect(ok, isFalse);
    });

    test('returns false for the reserved "Sin temporada" string', () async {
      final ok = await TemporadaService.addTemporada(
          AppConstants.temporadaSinTemporada);
      expect(ok, isFalse);
    });

    test('most recently added season appears first', () async {
      await TemporadaService.addTemporada('2024-2025');
      await TemporadaService.addTemporada('2025-2026');
      final result = await TemporadaService.getTemporadas();
      expect(result.first, equals('2025-2026'));
    });
  });

  group('TemporadaService - renameTemporada', () {
    test('renames an existing season', () async {
      await TemporadaService.addTemporada('Old name');
      final ok = await TemporadaService.renameTemporada('Old name', 'New name');
      expect(ok, isTrue);
      final temporadas = await TemporadaService.getTemporadas();
      expect(temporadas, contains('New name'));
      expect(temporadas, isNot(contains('Old name')));
    });

    test('updates active season when the renamed season was active', () async {
      await TemporadaService.addTemporada('Liga 2025');
      await TemporadaService.setTemporadaActiva('Liga 2025');
      await TemporadaService.renameTemporada('Liga 2025', 'Liga 2025-2026');
      final activa = await TemporadaService.getTemporadaActiva();
      expect(activa, equals('Liga 2025-2026'));
    });

    test('does not update active season when a non-active season is renamed',
        () async {
      await TemporadaService.addTemporada('A');
      await TemporadaService.addTemporada('B');
      await TemporadaService.setTemporadaActiva('A');
      await TemporadaService.renameTemporada('B', 'B renamed');
      final activa = await TemporadaService.getTemporadaActiva();
      expect(activa, equals('A'));
    });

    test('returns false when old name does not exist', () async {
      final ok = await TemporadaService.renameTemporada('Ghost', 'X');
      expect(ok, isFalse);
    });

    test('returns false when new name already exists as a different season',
        () async {
      await TemporadaService.addTemporada('A');
      await TemporadaService.addTemporada('B');
      final ok = await TemporadaService.renameTemporada('A', 'B');
      expect(ok, isFalse);
    });
  });

  group('TemporadaService - deleteTemporada', () {
    test('removes a season from the list', () async {
      await TemporadaService.addTemporada('2025');
      await TemporadaService.deleteTemporada('2025');
      expect(await TemporadaService.getTemporadas(), isNot(contains('2025')));
    });

    test('clears active season when the active season is deleted', () async {
      await TemporadaService.addTemporada('2025');
      await TemporadaService.setTemporadaActiva('2025');
      await TemporadaService.deleteTemporada('2025');
      expect(await TemporadaService.getTemporadaActiva(), isNull);
    });

    test('does not affect active season when a non-active season is deleted',
        () async {
      await TemporadaService.addTemporada('A');
      await TemporadaService.addTemporada('B');
      await TemporadaService.setTemporadaActiva('A');
      await TemporadaService.deleteTemporada('B');
      expect(await TemporadaService.getTemporadaActiva(), equals('A'));
    });
  });

  group('TemporadaService - getTemporadaActiva / setTemporadaActiva', () {
    test('returns null when no active season has been set', () async {
      expect(await TemporadaService.getTemporadaActiva(), isNull);
    });

    test('returns the name after setting an active season', () async {
      await TemporadaService.setTemporadaActiva('2025-2026');
      expect(await TemporadaService.getTemporadaActiva(), equals('2025-2026'));
    });

    test('returns null after setting active season to null (Sin temporada)',
        () async {
      await TemporadaService.setTemporadaActiva('2025');
      await TemporadaService.setTemporadaActiva(null);
      expect(await TemporadaService.getTemporadaActiva(), isNull);
    });
  });
}
