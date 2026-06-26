import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/utils/stats_filter.dart';

void main() {
  group('StatsFilter', () {
    test('includes season in cache key', () {
      const f1 = StatsFilter(tipo: 'Todos', temporada: '2025');
      const f2 = StatsFilter(tipo: 'Todos', temporada: '2026');

      expect(f1.cacheKey, isNot(equals(f2.cacheKey)));
    });

    test('copyWith can clear season', () {
      const filter = StatsFilter(temporada: '2025');
      final updated = filter.copyWith(clearTemporada: true);

      expect(updated.temporada, isNull);
    });

    test('equality accounts for season', () {
      final base = StatsFilter(
        tipo: 'Entrenamiento',
        datePreset: DateRangePreset.thisYear,
        customRange: DateTimeRange(
          start: DateTime(2025, 1, 1),
          end: DateTime(2025, 12, 31),
        ),
      );
      final withSeason = StatsFilter(
        tipo: 'Entrenamiento',
        temporada: '2025',
        datePreset: DateRangePreset.thisYear,
        customRange: DateTimeRange(
          start: DateTime(2025, 1, 1),
          end: DateTime(2025, 12, 31),
        ),
      );

      expect(base, isNot(equals(withSeason)));
    });
  });
}
