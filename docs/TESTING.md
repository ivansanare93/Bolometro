# Guía de Testing

Este documento describe la estrategia de testing comprehensiva implementada para Bolometro.

## Cobertura de Pruebas

### Pruebas Unitarias

#### Modelos
- `test/partida_model_test.dart` - Pruebas del modelo Partida
- `test/sesion_model_test.dart` - Pruebas del modelo Sesion

#### Proveedores
- `test/theme_provider_test.dart` - Pruebas de gestión de temas
- `test/language_provider_test.dart` - Pruebas de cambio de idioma

#### Servicios
- `test/analytics_service_test.dart` - Pruebas del servicio de analytics
- `test/data_repository_test.dart` - Pruebas del repositorio de datos (existente)
- `test/estadisticas_cache_test.dart` - Pruebas de caché de estadísticas (existente)

#### Utilidades
- `test/app_constants_test.dart` - Pruebas de constantes de la app (existente)
- `test/lazy_loading_test.dart` - Pruebas de carga diferida (existente)

### Pruebas de Widgets
- `test/skeleton_loaders_test.dart` - Pruebas de componentes skeleton loader

### Pruebas de Integración
- `test/integration_test.dart` - Pruebas de flujos de usuario end-to-end

## Ejecutar Pruebas

### Ejecutar todas las pruebas
```bash
flutter test
```

### Ejecutar archivo de prueba específico
```bash
flutter test test/partida_model_test.dart
```

### Ejecutar con cobertura
```bash
flutter test --coverage
```

### Ver reporte de cobertura
```bash
# Generar reporte HTML
genhtml coverage/lcov.info -o coverage/html

# Abrir en navegador
open coverage/html/index.html
```

## Integración CI/CD

Las pruebas se ejecutan automáticamente en el pipeline CI/CD:
- En cada pull request
- En pushes a las ramas main y develop
- Los reportes de cobertura se suben a Codecov

Ver `.github/workflows/flutter-ci.yml` para detalles.

## Escribir Nuevas Pruebas

### Ejemplo de Prueba Unitaria
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyClass', () {
    test('debería hacer algo', () {
      // Organizar (Arrange)
      // Actuar (Act)
      // Afirmar (Assert)
    });
  });
}
```

### Ejemplo de Prueba de Widget
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MyWidget debería mostrar texto', (WidgetTester tester) async {
    await tester.pumpWidget(MyWidget());
    expect(find.text('Hola'), findsOneWidget);
  });
}
```

## Mejores Prácticas de Testing

1. **Patrón Arrange-Act-Assert**: Estructura las pruebas claramente
2. **Nombres de Pruebas**: Usa nombres descriptivos que expliquen qué se está probando
3. **Mock de Dependencias Externas**: Usa mocks para Firebase, llamadas de red, etc.
4. **Prueba Casos Límite**: No solo rutas felices
5. **Mantén las Pruebas Rápidas**: Evita retrasos innecesarios
6. **Pruebas Independientes**: Cada prueba debe poder ejecutarse independientemente

## Limitaciones Conocidas

- Los servicios de Firebase (Auth, Firestore, Analytics) requieren mocking para pruebas apropiadas
- Algunas pruebas de integración están comentadas pendiente configuración de pruebas de Firebase
- Las pruebas de widgets para pantallas complejas pueden requerir mocking extensivo

## Mejoras Futuras

- [ ] Agregar pruebas golden para consistencia de UI
- [ ] Aumentar cobertura a 80%+
- [ ] Agregar pruebas de rendimiento
- [ ] Mock de servicios de Firebase para pruebas de integración
- [ ] Agregar pruebas de captura de pantalla para diferentes tamaños de pantalla
