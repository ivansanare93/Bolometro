import 'package:bolometro/utils/app_constants.dart';
import 'package:bolometro/widgets/marcador_bolos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildMarcadorUnderTest() {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 140,
          child: MarcadorBolos(
            frames: List.generate(10, (_) => List.filled(3, '')),
            puntuaciones: List<int?>.filled(AppConstants.totalFrames, null),
            frameActivo: 0,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'moves horizontally just enough when advancing to the next frame',
    (tester) async {
      await tester.pumpWidget(_buildMarcadorUnderTest());

      final state =
          tester.state<MarcadorBolosState>(find.byType(MarcadorBolos));

      state.setTiroActivo(1, 0);
      await tester.pumpAndSettle();

      final scrollableState = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );

      expect(scrollableState.position.pixels, greaterThan(0));
      expect(scrollableState.position.pixels, lessThan(60));
    },
  );
}
