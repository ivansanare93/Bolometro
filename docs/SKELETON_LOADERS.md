# Skeleton Loaders Guide

Skeleton loaders provide visual feedback while content is loading, improving perceived performance and user experience.

## Overview

Bolometro uses the `shimmer` package to create skeleton loading effects. These are implemented in `lib/widgets/skeleton_loaders.dart`.

## Available Skeleton Widgets

### 1. SessionCardSkeleton

Mimics the appearance of a session card while loading.

**Usage**:
```dart
import 'package:bolometro/widgets/skeleton_loaders.dart';

// In your widget build method
isLoading 
  ? const SessionCardSkeleton()
  : SessionCard(session: session)
```

**Appearance**:
- Card container
- Title placeholder (150px wide)
- Subtitle placeholder (100px wide)
- Three metric boxes in a row

### 2. StatisticsCardSkeleton

Used for loading KPI cards on the statistics screen.

**Usage**:
```dart
isLoading
  ? const StatisticsCardSkeleton()
  : StatisticsCard(
      title: 'Average',
      value: '150',
    )
```

**Appearance**:
- Small card
- Label placeholder (80px)
- Value placeholder (120px)

### 3. ChartSkeleton

Skeleton for chart components with customizable height.

**Usage**:
```dart
// Default height (200px)
isLoading
  ? const ChartSkeleton()
  : MyChart(data: data)

// Custom height
isLoading
  ? const ChartSkeleton(height: 300)
  : MyChart(data: data)
```

**Parameters**:
- `height`: Height of the skeleton (default: 200)

**Appearance**:
- Card with padding
- Title placeholder
- Large rectangular placeholder for chart area

### 4. ListItemSkeleton

Generic skeleton for list items.

**Usage**:
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

**Appearance**:
- Left square icon placeholder (60x60)
- Two text line placeholders on the right

## Implementation Examples

### Loading Session List

```dart
class SessionsList extends StatelessWidget {
  final bool isLoading;
  final List<Sesion> sessions;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ListView.builder(
        itemCount: 5, // Show 5 skeleton items while loading
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

### Loading Statistics Cards

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
    
    // Simulate loading
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
        // More cards...
      ],
    );
  }
}
```

### Loading Charts

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

### Pull-to-Refresh with Skeletons

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

## Customization

### Creating Custom Skeletons

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

### Dark Mode Support

Skeletons automatically adapt to dark mode by using theme colors:

```dart
Shimmer.fromColors(
  baseColor: Theme.of(context).brightness == Brightness.dark
    ? Colors.grey[800]!
    : Colors.grey[300]!,
  highlightColor: Theme.of(context).brightness == Brightness.dark
    ? Colors.grey[700]!
    : Colors.grey[100]!,
  child: // Your skeleton content
)
```

## Best Practices

### 1. Match Real Content Size

Skeletons should closely match the size and layout of actual content:

```dart
// Bad - skeleton doesn't match real content
const SessionCardSkeleton() // Shows 3 metrics
SessionCard(session: session) // Shows 5 metrics

// Good - skeleton matches
const SessionCardSkeleton() // Shows 5 metrics
SessionCard(session: session) // Shows 5 metrics
```

### 2. Show Appropriate Number

Display a reasonable number of skeleton items:

```dart
// Bad - too many skeletons
itemCount: 100

// Good - just enough to fill visible area
itemCount: 5
```

### 3. Avoid Nested Skeletons

Don't nest shimmer effects:

```dart
// Bad
Shimmer.fromColors(
  child: Shimmer.fromColors(
    child: Container(),
  ),
)

// Good
Shimmer.fromColors(
  child: Container(),
)
```

### 4. Quick Transitions

Remove skeletons as soon as data is ready:

```dart
// Good
setState(() {
  _data = loadedData;
  _isLoading = false; // Immediately hide skeleton
});
```

### 5. Consistent Timing

Use consistent loading durations across the app:

```dart
// Define in app constants
static const Duration skeletonMinDuration = Duration(milliseconds: 300);
static const Duration skeletonMaxDuration = Duration(seconds: 10);
```

## Performance Tips

### 1. Limit Shimmer Widgets

Too many shimmer animations can impact performance:

```dart
// Consider using a simple grey placeholder for off-screen items
if (index < 5) {
  return const SessionCardSkeleton(); // Animated
} else {
  return const SessionCardPlaceholder(); // Static grey box
}
```

### 2. Dispose Properly

Shimmer uses animation controllers that should be disposed:

```dart
// The shimmer package handles this automatically
// But if creating custom skeletons, ensure proper disposal
```

### 3. Use const Constructors

Always use const for skeleton widgets:

```dart
// Good
const SessionCardSkeleton()

// Bad
SessionCardSkeleton()
```

## Testing Skeletons

### Visual Testing

```dart
testWidgets('Skeleton displays correctly', (tester) async {
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

### Loading State Testing

```dart
testWidgets('Shows skeleton while loading', (tester) async {
  await tester.pumpWidget(MyWidget(isLoading: true));
  
  expect(find.byType(SessionCardSkeleton), findsWidgets);
  expect(find.byType(SessionCard), findsNothing);
});

testWidgets('Shows content when loaded', (tester) async {
  await tester.pumpWidget(MyWidget(isLoading: false));
  
  expect(find.byType(SessionCardSkeleton), findsNothing);
  expect(find.byType(SessionCard), findsWidgets);
});
```

## Resources

- [Shimmer Package](https://pub.dev/packages/shimmer)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Material Design - Placeholders](https://material.io/design/communication/data-formats.html#loading-data)
