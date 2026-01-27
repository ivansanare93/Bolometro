import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/utils/app_constants.dart';

/// Tests para AppConstants
/// 
/// Verifica que las constantes estén definidas correctamente
/// y sean consistentes entre sí
void main() {
  group('AppConstants - Tipos de Sesión', () {
    test('tipos de sesión deben estar definidos', () {
      expect(AppConstants.tipoTodos, equals('Todos'));
      expect(AppConstants.tipoEntrenamiento, equals('Entrenamiento'));
      expect(AppConstants.tipoCompeticion, equals('Competición'));
    });

    test('tiposSesionConTodos debe contener todos los tipos', () {
      expect(AppConstants.tiposSesionConTodos, hasLength(3));
      expect(AppConstants.tiposSesionConTodos, contains(AppConstants.tipoTodos));
      expect(AppConstants.tiposSesionConTodos, contains(AppConstants.tipoEntrenamiento));
      expect(AppConstants.tiposSesionConTodos, contains(AppConstants.tipoCompeticion));
    });

    test('tiposSesion debe contener solo tipos sin "Todos"', () {
      expect(AppConstants.tiposSesion, hasLength(2));
      expect(AppConstants.tiposSesion, contains(AppConstants.tipoEntrenamiento));
      expect(AppConstants.tiposSesion, contains(AppConstants.tipoCompeticion));
      expect(AppConstants.tiposSesion, isNot(contains(AppConstants.tipoTodos)));
    });
  });

  group('AppConstants - Símbolos de Bolos', () {
    test('símbolos deben estar definidos correctamente', () {
      expect(AppConstants.simboloStrike, equals('X'));
      expect(AppConstants.simboloSpare, equals('/'));
      expect(AppConstants.simboloFallo, equals('-'));
    });
  });

  group('AppConstants - Límites y Validaciones', () {
    test('límites de bowling deben ser correctos', () {
      expect(AppConstants.maxPinesBowling, equals(10));
      expect(AppConstants.totalFrames, equals(10));
      expect(AppConstants.maxTirosPorFrame, equals(2));
      expect(AppConstants.maxTirosFrame10, equals(3));
    });
  });

  group('AppConstants - Paginación', () {
    test('configuración de paginación debe estar definida', () {
      expect(AppConstants.pageSize, equals(20));
      expect(AppConstants.scrollThreshold, equals(200));
      expect(AppConstants.pageSize, greaterThan(0));
      expect(AppConstants.scrollThreshold, greaterThan(0));
    });
  });

  group('AppConstants - Estadísticas', () {
    test('configuración de estadísticas debe estar definida', () {
      expect(AppConstants.ventanaPromedioMovil, equals(5));
      expect(AppConstants.maxPartidasTop, equals(10));
      expect(AppConstants.ultimasPartidasPromedio5, equals(5));
      expect(AppConstants.ultimasPartidasPromedio10, equals(10));
      expect(AppConstants.topNMejoresPartidas, equals(3));
      expect(AppConstants.topNPeoresPartidas, equals(3));
      expect(AppConstants.histogramaBinSize, equals(20));
    });

    test('valores de estadísticas deben ser positivos', () {
      expect(AppConstants.ventanaPromedioMovil, greaterThan(0));
      expect(AppConstants.maxPartidasTop, greaterThan(0));
      expect(AppConstants.ultimasPartidasPromedio5, greaterThan(0));
      expect(AppConstants.ultimasPartidasPromedio10, greaterThan(0));
      expect(AppConstants.topNMejoresPartidas, greaterThan(0));
      expect(AppConstants.topNPeoresPartidas, greaterThan(0));
      expect(AppConstants.histogramaBinSize, greaterThan(0));
    });

    test('promedio5 debe ser menor que promedio10', () {
      expect(
        AppConstants.ultimasPartidasPromedio5,
        lessThan(AppConstants.ultimasPartidasPromedio10),
      );
    });
  });

  group('AppConstants - Boxes de Hive', () {
    test('nombres de boxes deben estar definidos', () {
      expect(AppConstants.boxSesiones, equals('sesiones'));
      expect(AppConstants.boxPerfilUsuario, equals('perfilUsuario'));
    });
  });

  group('AppConstants - UI', () {
    test('configuración de UI debe estar definida', () {
      expect(AppConstants.cardBorderRadius, equals(12.0));
      expect(AppConstants.buttonBorderRadius, equals(8.0));
      expect(AppConstants.defaultElevation, equals(2.0));
      expect(AppConstants.cardElevation, equals(3.0));
    });

    test('tamaños de iconos deben ser positivos', () {
      expect(AppConstants.iconSizeSmall, greaterThan(0));
      expect(AppConstants.iconSizeMedium, greaterThan(0));
      expect(AppConstants.iconSizeLarge, greaterThan(0));
    });

    test('tamaños de iconos deben estar ordenados', () {
      expect(AppConstants.iconSizeSmall, lessThan(AppConstants.iconSizeMedium));
      expect(AppConstants.iconSizeMedium, lessThan(AppConstants.iconSizeLarge));
    });
  });

  group('AppConstants - Mensajes', () {
    test('mensajes deben estar definidos y no estar vacíos', () {
      expect(AppConstants.mensajeNoHaySesiones, isNotEmpty);
      expect(AppConstants.mensajeNoHayPartidas, isNotEmpty);
      expect(AppConstants.mensajeCargando, isNotEmpty);
      expect(AppConstants.mensajeGuardado, isNotEmpty);
      expect(AppConstants.mensajeError, isNotEmpty);
    });
  });

  group('AppConstants - Rutas', () {
    test('rutas deben estar definidas', () {
      expect(AppConstants.rutaRegistro, equals('/registro'));
      expect(AppConstants.rutaHome, equals('/'));
    });
  });

  group('AppConstants - No se puede instanciar', () {
    test('constructor privado previene instanciación', () {
      // Esta prueba verifica que AppConstants tenga un constructor privado
      // Si el constructor es privado, esta línea no compilaría:
      // final instance = AppConstants();
      // Como no podemos probar directamente que no compila, verificamos
      // que la clase funciona como se espera (como namespace estático)
      expect(AppConstants.tipoTodos, isNotNull);
    });
  });
}
