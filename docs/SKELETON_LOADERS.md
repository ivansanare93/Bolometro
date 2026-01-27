# Guía de Skeleton Loaders

Los skeleton loaders proporcionan retroalimentación visual mientras el contenido se carga, mejorando el rendimiento percibido y la experiencia del usuario.

## Descripción General

Bolometro utiliza el paquete `shimmer` para crear efectos de carga tipo skeleton. Estos están implementados en `lib/widgets/skeleton_loaders.dart`.

## Widgets Skeleton Disponibles

### 1. SessionCardSkeleton

Imita la apariencia de una tarjeta de sesión mientras se carga.

**Uso**:
```dart
import 'package:bolometro/widgets/skeleton_loaders.dart';

// En el método build de tu widget
isLoading 
  ? const SessionCardSkeleton()
  : SessionCard(session: session)
```

**Apariencia**:
- Contenedor de tarjeta
- Marcador de posición del título (150px de ancho)
- Marcador de posición del subtítulo (100px de ancho)
- Tres cuadros de métricas en fila

### 2. StatisticsCardSkeleton

Usado para cargar tarjetas KPI en la pantalla de estadísticas.

**Uso**:
```dart
isLoading
  ? const StatisticsCardSkeleton()
  : StatisticsCard(
      title: 'Promedio',
      value: '150',
    )
```

**Apariencia**:
- Tarjeta pequeña
- Marcador de posición de etiqueta (80px)
- Marcador de posición de valor (120px)

### 3. ChartSkeleton

Skeleton para componentes de gráficos con altura personalizable.

**Uso**:
```dart
// Altura por defecto (200px)
isLoading
  ? const ChartSkeleton()
  : MyChart(data: data)

// Altura personalizada
isLoading
  ? const ChartSkeleton(height: 300)
  : MyChart(data: data)
```

**Parámetros**:
- `height`: Altura del skeleton (por defecto: 200)

**Apariencia**:
- Tarjeta con padding
- Marcador de posición del título
- Marcador de posición rectangular grande para el área del gráfico

### 4. ListItemSkeleton

Skeleton genérico para elementos de lista.

**Uso**:
```dart
ListView.builder(
  itemCount: isLoading ? 5 : items.length,
  itemBuilder: (context, index) {
    if (isLoading) {
      return const ListItemSkeleton();
    }
    return ListItem(item: items[index]);
  },
)
```

**Apariencia**:
- Marcador de posición de ícono cuadrado izquierdo (60x60)
- Dos marcadores de posición de líneas de texto a la derecha

## Ejemplos de Implementación

### Cargando Lista de Sesiones

```dart
class SessionsList extends StatelessWidget {
  final bool isLoading;
  final List<Sesion> sessions;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ListView.builder(
        itemCount: 5, // Mostrar 5 elementos skeleton mientras se carga
        itemBuilder: (context, index) => const SessionCardSkeleton(),
      );
    }

    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        return SessionCard(session: sessions[index]);
      },
    );
  }
}
```

### Cargando Tarjetas de Estadísticas

```dart
class StatisticsScreen extends StatefulWidget {
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    // Simular carga
    await Future.delayed(const Duration(seconds: 2));
    _stats = await calculateStatistics();
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      children: [
        _isLoading
          ? const StatisticsCardSkeleton()
          : StatisticsCard(
              title: 'Promedio',
              value: _stats['average'].toString(),
            ),
        _isLoading
          ? const StatisticsCardSkeleton()
          : StatisticsCard(
              title: 'Mejor',
              value: _stats['best'].toString(),
            ),
        // Más tarjetas...
      ],
    );
  }
}
```

### Cargando Gráficos

```dart
class ChartWidget extends StatefulWidget {
  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  bool _isLoading = true;
  List<ChartData> _data = [];

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() => _isLoading = true);
    _data = await fetchChartData();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ChartSkeleton(height: 250);
    }

    return LineChart(data: _data);
  }
}
```

### Pull-to-Refresh con Skeletons

```dart
class SessionsListScreen extends StatefulWidget {
  @override
  State<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends State<SessionsListScreen> {
  bool _isLoading = false;
  List<Sesion> _sessions = [];

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    
    try {
      _sessions = await fetchSessions();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        itemCount: _isLoading ? 5 : _sessions.length,
        itemBuilder: (context, index) {
          if (_isLoading) {
            return const SessionCardSkeleton();
          }
          return SessionCard(session: _sessions[index]);
        },
      ),
    );
  }
}
```

## Personalización

### Crear Skeletons Personalizados

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class MyCustomSkeleton extends StatelessWidget {
  const MyCustomSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 200,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Soporte para Modo Oscuro

Los skeletons se adaptan automáticamente al modo oscuro usando colores del tema:

```dart
Shimmer.fromColors(
  baseColor: Theme.of(context).brightness == Brightness.dark
    ? Colors.grey[800]!
    : Colors.grey[300]!,
  highlightColor: Theme.of(context).brightness == Brightness.dark
    ? Colors.grey[700]!
    : Colors.grey[100]!,
  child: // Tu contenido skeleton
)
```

## Mejores Prácticas

### 1. Coincidir con el Tamaño del Contenido Real

Los skeletons deben coincidir estrechamente con el tamaño y diseño del contenido real:

```dart
// Mal - skeleton no coincide con contenido real
const SessionCardSkeleton() // Muestra 3 métricas
SessionCard(session: session) // Muestra 5 métricas

// Bien - skeleton coincide
const SessionCardSkeleton() // Muestra 5 métricas
SessionCard(session: session) // Muestra 5 métricas
```

### 2. Mostrar Número Apropiado

Muestra un número razonable de elementos skeleton:

```dart
// Mal - demasiados skeletons
itemCount: 100

// Bien - suficientes para llenar el área visible
itemCount: 5
```

### 3. Evitar Skeletons Anidados

No anides efectos shimmer:

```dart
// Mal
Shimmer.fromColors(
  child: Shimmer.fromColors(
    child: Container(),
  ),
)

// Bien
Shimmer.fromColors(
  child: Container(),
)
```

### 4. Transiciones Rápidas

Remueve skeletons tan pronto como los datos estén listos:

```dart
// Bien
setState(() {
  _data = loadedData;
  _isLoading = false; // Ocultar skeleton inmediatamente
});
```

### 5. Tiempo Consistente

Usa duraciones de carga consistentes en toda la app:

```dart
// Definir en constantes de la app
static const Duration skeletonMinDuration = Duration(milliseconds: 300);
static const Duration skeletonMaxDuration = Duration(seconds: 10);
```

## Consejos de Rendimiento

### 1. Limitar Widgets Shimmer

Demasiadas animaciones shimmer pueden impactar el rendimiento:

```dart
// Considera usar un marcador de posición gris simple para elementos fuera de pantalla
if (index < 5) {
  return const SessionCardSkeleton(); // Animado
} else {
  return const SessionCardPlaceholder(); // Cuadro gris estático
}
```

### 2. Desechar Apropiadamente

Shimmer usa controladores de animación que deben ser desechados:

```dart
// El paquete shimmer maneja esto automáticamente
// Pero si creas skeletons personalizados, asegura el desechado apropiado
```

### 3. Usar Constructores const

Siempre usa const para widgets skeleton:

```dart
// Bien
const SessionCardSkeleton()

// Mal
SessionCardSkeleton()
```

## Probar Skeletons

### Pruebas Visuales

```dart
testWidgets('Skeleton se muestra correctamente', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SessionCardSkeleton(),
      ),
    ),
  );

  expect(find.byType(SessionCardSkeleton), findsOneWidget);
  expect(find.byType(Card), findsOneWidget);
});
```

### Pruebas de Estado de Carga

```dart
testWidgets('Muestra skeleton mientras se carga', (tester) async {
  await tester.pumpWidget(MyWidget(isLoading: true));
  
  expect(find.byType(SessionCardSkeleton), findsWidgets);
  expect(find.byType(SessionCard), findsNothing);
});

testWidgets('Muestra contenido cuando está cargado', (tester) async {
  await tester.pumpWidget(MyWidget(isLoading: false));
  
  expect(find.byType(SessionCardSkeleton), findsNothing);
  expect(find.byType(SessionCard), findsWidgets);
});
```

## Recursos

- [Paquete Shimmer](https://pub.dev/packages/shimmer)
- [Mejores Prácticas de Rendimiento de Flutter](https://docs.flutter.dev/perf/best-practices)
- [Material Design - Marcadores de Posición](https://material.io/design/communication/data-formats.html#loading-data)
