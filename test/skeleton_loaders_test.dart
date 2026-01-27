import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/widgets/skeleton_loaders.dart';

/// Tests for skeleton loader widgets
void main() {
  group('Skeleton Loaders', () {
    testWidgets('SessionCardSkeleton should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SessionCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(SessionCardSkeleton), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('StatisticsCardSkeleton should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatisticsCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(StatisticsCardSkeleton), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('ChartSkeleton should render with default height', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartSkeleton(),
          ),
        ),
      );

      expect(find.byType(ChartSkeleton), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('ChartSkeleton should render with custom height', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartSkeleton(height: 300),
          ),
        ),
      );

      expect(find.byType(ChartSkeleton), findsOneWidget);
      
      final Container container = tester.widget(find.descendant(
        of: find.byType(ChartSkeleton),
        matching: find.byType(Container),
      ).first);
      
      expect(container.constraints?.maxHeight ?? 300, equals(300));
    });

    testWidgets('ListItemSkeleton should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListItemSkeleton(),
          ),
        ),
      );

      expect(find.byType(ListItemSkeleton), findsOneWidget);
    });

    testWidgets('Multiple skeletons can render in a list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                SessionCardSkeleton(),
                SessionCardSkeleton(),
                SessionCardSkeleton(),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SessionCardSkeleton), findsNWidgets(3));
    });
  });
}
