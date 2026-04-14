import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/utils/estadisticas_cache.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/utils/app_constants.dart';

/// Tests para EstadisticasCache
/// 
/// Verifica que el cache funcione correctamente:
/// 1. Cache se inicializa vacío
/// 2. Cache se actualiza cuando hay nuevos datos
/// 3. Cache se reutiliza cuando no hay cambios
/// 4. Cache se invalida correctamente
void main() {
  group('EstadisticasCache', () {
    late EstadisticasCache cache;

    setUp(() {
      cache = EstadisticasCache();
    });

    test('cache debe estar vacío inicialmente', () {
      expect(cache.hasCache, isFalse);
      expect(cache.timeSinceLastUpdate, isNull);
    });

    test('getEstadisticas debe calcular y cachear resultados', () {
      // Arrange
      final sesion = Sesion(
        fecha: DateTime.now(),
        lugar: 'Test',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [
          Partida(
            total: 150,
            frames: List.generate(
              AppConstants.totalFrames,
              (_) => [AppConstants.simboloStrike],
            ),
          ),
        ],
      );

      // Act
      final stats = cache.getEstadisticas([sesion]);

      // Assert
      expect(cache.hasCache, isTrue);
      expect(stats, isNotEmpty);
      expect(stats['totalSesiones'], equals(1));
      expect(stats['totalPartidas'], equals(1));
      expect(stats['promedioGeneral'], equals(150.0));
    });

    test('cache debe reutilizarse cuando los datos no cambian', () {
      // Arrange
      final sesion = Sesion(
        fecha: DateTime.now(),
        lugar: 'Test',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [
          Partida(
            total: 100,
            frames: List.generate(
              AppConstants.totalFrames,
              (_) => [AppConstants.simboloFallo],
            ),
          ),
        ],
      );

      // Act
      final stats1 = cache.getEstadisticas([sesion]);
      final time1 = cache.timeSinceLastUpdate;
      
      // Pequeña pausa para asegurar que el tiempo cambie
      Future.delayed(const Duration(milliseconds: 10));
      
      final stats2 = cache.getEstadisticas([sesion]);
      final time2 = cache.timeSinceLastUpdate;

      // Assert
      expect(stats1, equals(stats2));
      // El tiempo debe ser el mismo porque usó cache
      expect(time1!.inMilliseconds, lessThanOrEqualTo(time2!.inMilliseconds));
    });

    test('cache debe recalcular cuando cambia el número de sesiones', () {
      // Arrange
      final sesion1 = Sesion(
        fecha: DateTime.now(),
        lugar: 'Test 1',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [
          Partida(
            total: 100,
            frames: List.generate(
              AppConstants.totalFrames,
              (_) => [AppConstants.simboloFallo],
            ),
          ),
        ],
      );

      final sesion2 = Sesion(
        fecha: DateTime.now(),
        lugar: 'Test 2',
        tipo: AppConstants.tipoCompeticion,
        partidas: [
          Partida(
            total: 200,
            frames: List.generate(
              AppConstants.totalFrames,
              (_) => [AppConstants.simboloStrike],
            ),
          ),
        ],
      );

      // Act
      final stats1 = cache.getEstadisticas([sesion1]);
      final stats2 = cache.getEstadisticas([sesion1, sesion2]);

      // Assert
      expect(stats1['totalSesiones'], equals(1));
      expect(stats2['totalSesiones'], equals(2));
      expect(stats2['totalPartidas'], equals(2));
      expect(stats2['promedioGeneral'], equals(150.0)); // (100 + 200) / 2
    });

    test('invalidateCache debe limpiar el cache', () {
      // Arrange
      final sesion = Sesion(
        fecha: DateTime.now(),
        lugar: 'Test',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [
          Partida(
            total: 100,
            frames: List.generate(
              AppConstants.totalFrames,
              (_) => [AppConstants.simboloFallo],
            ),
          ),
        ],
      );
      
      cache.getEstadisticas([sesion]);
      expect(cache.hasCache, isTrue);

      // Act
      cache.invalidateCache();

      // Assert
      expect(cache.hasCache, isFalse);
      expect(cache.timeSinceLastUpdate, isNull);
    });

    test('getEstadisticas debe retornar estadísticas vacías cuando no hay partidas', () {
      // Arrange
      final sesion = Sesion(
        fecha: DateTime.now(),
        lugar: 'Test',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [],
      );

      // Act
      final stats = cache.getEstadisticas([sesion]);

      // Assert
      expect(stats['totalPartidas'], equals(0));
      expect(stats['totalSesiones'], equals(1));
      expect(stats['promedioGeneral'], equals(0.0));
      expect(stats['mejorPartida'], isNull);
      expect(stats['peorPartida'], isNull);
    });

    test('cache debe incluir todas las estadísticas calculadas', () {
      // Arrange
      final sesion = Sesion(
        fecha: DateTime.now(),
        lugar: 'Test',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [
          Partida(
            total: 150,
            frames: List.generate(
              AppConstants.totalFrames,
              (_) => [AppConstants.simboloStrike],
            ),
          ),
        ],
      );

      // Act
      final stats = cache.getEstadisticas([sesion]);

      // Assert - verificar que todas las claves esperadas existen
      expect(stats.containsKey('porcentajes'), isTrue);
      expect(stats.containsKey('rachaStrikes'), isTrue);
      expect(stats.containsKey('rachaSpares'), isTrue);
      expect(stats.containsKey('promedioGeneral'), isTrue);
      expect(stats.containsKey('mejorPartida'), isTrue);
      expect(stats.containsKey('peorPartida'), isTrue);
      expect(stats.containsKey('sesionRecord'), isTrue);
      expect(stats.containsKey('sesionPeor'), isTrue);
      expect(stats.containsKey('mejorEntrenamiento'), isTrue);
      expect(stats.containsKey('mejorCompeticion'), isTrue);
      expect(stats.containsKey('promedioUltimas5'), isTrue);
      expect(stats.containsKey('promedioUltimas10'), isTrue);
      expect(stats.containsKey('histograma'), isTrue);
      expect(stats.containsKey('topMejores'), isTrue);
      expect(stats.containsKey('topPeores'), isTrue);
      expect(stats.containsKey('promedioMovil'), isTrue);
      expect(stats.containsKey('totalPartidas'), isTrue);
      expect(stats.containsKey('totalSesiones'), isTrue);
    });
  });

  group('EstadisticasCache – filter-keyed cache', () {
    late EstadisticasCache cache;

    Sesion _makeSesion(int total, String tipo) => Sesion(
          fecha: DateTime.now(),
          lugar: 'Test',
          tipo: tipo,
          partidas: [
            Partida(
              total: total,
              frames: List.generate(
                AppConstants.totalFrames,
                (_) => [AppConstants.simboloStrike],
              ),
            ),
          ],
        );

    setUp(() {
      cache = EstadisticasCache();
    });

    test('diferentes claves de filtro producen caches independientes', () {
      final sesiones = [
        _makeSesion(150, AppConstants.tipoEntrenamiento),
        _makeSesion(200, AppConstants.tipoCompeticion),
      ];

      final statsAll = cache.getEstadisticas(sesiones, filterKey: 'Todos_allTime_all');
      final statsTraining = cache.getEstadisticas(
        [sesiones[0]],
        filterKey: 'Entrenamiento_allTime_all',
      );

      // Different filter keys ⟹ different results
      expect(statsAll['totalPartidas'], equals(2));
      expect(statsTraining['totalPartidas'], equals(1));
    });

    test('misma clave de filtro reutiliza el cache', () {
      final sesiones = [_makeSesion(150, AppConstants.tipoEntrenamiento)];
      const key = 'Todos_allTime_all';

      final stats1 = cache.getEstadisticas(sesiones, filterKey: key);
      final stats2 = cache.getEstadisticas(sesiones, filterKey: key);

      // Same object reference ⟹ cache was reused
      expect(identical(stats1, stats2), isTrue);
    });

    test('invalidateCache borra también las entradas con clave de filtro', () {
      final sesiones = [_makeSesion(150, AppConstants.tipoEntrenamiento)];
      const key = 'Todos_allTime_all';

      cache.getEstadisticas(sesiones, filterKey: key);
      cache.invalidateCache();
      expect(cache.hasCache, isFalse);

      // After invalidation a new call should recalculate (not error)
      final stats = cache.getEstadisticas(sesiones, filterKey: key);
      expect(stats['totalPartidas'], equals(1));
    });
  });
}
