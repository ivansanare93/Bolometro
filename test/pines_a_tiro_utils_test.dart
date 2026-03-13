import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/utils/pines_a_tiro_utils.dart';

void main() {
  // Helper that builds an empty 10×3 frames grid
  List<List<String>> _emptyFrames() =>
      List.generate(10, (_) => List.filled(3, ''));

  // Helper that builds an empty pinesPorTiroFrame (3 null slots)
  List<List<int>?> _emptyTiros() => List.filled(3, null);

  group('pinesAValorTiro – frames 1-9', () {
    test('tiro 0: 10 pines → X (strike)', () {
      final valor = pinesAValorTiro(
        frame: 0,
        tiro: 0,
        seleccionados: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        pinesPorTiroFrame: _emptyTiros(),
        framesText: _emptyFrames(),
      );
      expect(valor, 'X');
    });

    test('tiro 0: 0 pines → - (fallo)', () {
      final valor = pinesAValorTiro(
        frame: 3,
        tiro: 0,
        seleccionados: [],
        pinesPorTiroFrame: _emptyTiros(),
        framesText: _emptyFrames(),
      );
      expect(valor, '-');
    });

    test('tiro 0: 5 pines → "5"', () {
      final valor = pinesAValorTiro(
        frame: 2,
        tiro: 0,
        seleccionados: [1, 2, 3, 4, 5],
        pinesPorTiroFrame: _emptyTiros(),
        framesText: _emptyFrames(),
      );
      expect(valor, '5');
    });

    test('tiro 1: spare when union covers all 10 pins', () {
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = [1, 2, 3, 4, 5]; // 5 pins knocked in tiro 0
      final valor = pinesAValorTiro(
        frame: 0,
        tiro: 1,
        seleccionados: [6, 7, 8, 9, 10], // remaining 5
        pinesPorTiroFrame: tiros,
        framesText: _emptyFrames(),
      );
      expect(valor, '/');
    });

    test('tiro 1: not a spare when union < 10', () {
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = [1, 2, 3];
      final valor = pinesAValorTiro(
        frame: 0,
        tiro: 1,
        seleccionados: [4, 5], // only 2 more pins
        pinesPorTiroFrame: tiros,
        framesText: _emptyFrames(),
      );
      expect(valor, '2');
    });

    test('tiro 1: fallo (0 pins)', () {
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = [1, 2, 3];
      final valor = pinesAValorTiro(
        frame: 0,
        tiro: 1,
        seleccionados: [],
        pinesPorTiroFrame: tiros,
        framesText: _emptyFrames(),
      );
      expect(valor, '-');
    });
  });

  group('pinesAValorTiro – frame 10, tiro 0', () {
    test('10 pins → X', () {
      final valor = pinesAValorTiro(
        frame: 9,
        tiro: 0,
        seleccionados: List.generate(10, (i) => i + 1),
        pinesPorTiroFrame: _emptyTiros(),
        framesText: _emptyFrames(),
      );
      expect(valor, 'X');
    });

    test('0 pins → -', () {
      final valor = pinesAValorTiro(
        frame: 9,
        tiro: 0,
        seleccionados: [],
        pinesPorTiroFrame: _emptyTiros(),
        framesText: _emptyFrames(),
      );
      expect(valor, '-');
    });

    test('7 pins → "7"', () {
      final valor = pinesAValorTiro(
        frame: 9,
        tiro: 0,
        seleccionados: [1, 2, 3, 4, 5, 6, 7],
        pinesPorTiroFrame: _emptyTiros(),
        framesText: _emptyFrames(),
      );
      expect(valor, '7');
    });
  });

  group('pinesAValorTiro – frame 10, tiro 1', () {
    test('10 pins after strike → X', () {
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = List.generate(10, (i) => i + 1);
      final frames = _emptyFrames();
      frames[9][0] = 'X';
      final valor = pinesAValorTiro(
        frame: 9,
        tiro: 1,
        seleccionados: List.generate(10, (i) => i + 1),
        pinesPorTiroFrame: tiros,
        framesText: frames,
      );
      expect(valor, 'X');
    });

    test('spare after non-strike tiro 0', () {
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = [1, 2, 3, 4, 5];
      final frames = _emptyFrames();
      frames[9][0] = '5';
      final valor = pinesAValorTiro(
        frame: 9,
        tiro: 1,
        seleccionados: [6, 7, 8, 9, 10],
        pinesPorTiroFrame: tiros,
        framesText: frames,
      );
      expect(valor, '/');
    });

    test('fallo (0 pins)', () {
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = [1, 2, 3];
      final valor = pinesAValorTiro(
        frame: 9,
        tiro: 1,
        seleccionados: [],
        pinesPorTiroFrame: tiros,
        framesText: _emptyFrames(),
      );
      expect(valor, '-');
    });
  });

  group('pinesAValorTiro – frame 10, tiro 2', () {
    test('strike after two strikes → X', () {
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = List.generate(10, (i) => i + 1);
      tiros[1] = List.generate(10, (i) => i + 1);
      final frames = _emptyFrames();
      frames[9][0] = 'X';
      frames[9][1] = 'X';
      final valor = pinesAValorTiro(
        frame: 9,
        tiro: 2,
        seleccionados: List.generate(10, (i) => i + 1),
        pinesPorTiroFrame: tiros,
        framesText: frames,
      );
      expect(valor, 'X');
    });

    test('spare after strike in tiro 0, partial in tiro 1', () {
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = List.generate(10, (i) => i + 1); // strike
      tiros[1] = [1, 2, 3, 4, 5]; // 5 pins in tiro 1
      final frames = _emptyFrames();
      frames[9][0] = 'X';
      frames[9][1] = '5';
      final valor = pinesAValorTiro(
        frame: 9,
        tiro: 2,
        seleccionados: [6, 7, 8, 9, 10], // remaining 5
        pinesPorTiroFrame: tiros,
        framesText: frames,
      );
      expect(valor, '/');
    });

    test('3 pins after spare in first two tiros', () {
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = [1, 2, 3, 4, 5];
      tiros[1] = [6, 7, 8, 9, 10];
      final frames = _emptyFrames();
      frames[9][0] = '5';
      frames[9][1] = '/';
      final valor = pinesAValorTiro(
        frame: 9,
        tiro: 2,
        seleccionados: [1, 2, 3],
        pinesPorTiroFrame: tiros,
        framesText: frames,
      );
      expect(valor, '3');
    });

    test('no third tiro right → returns -', () {
      // Neither strike nor spare in first two shots
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = [1, 2, 3];
      tiros[1] = [4, 5]; // total 5, not a spare
      final frames = _emptyFrames();
      frames[9][0] = '3';
      frames[9][1] = '2';
      final valor = pinesAValorTiro(
        frame: 9,
        tiro: 2,
        seleccionados: [6],
        pinesPorTiroFrame: tiros,
        framesText: frames,
      );
      expect(valor, '-');
    });
  });

  // ---------------------------------------------------------------------------
  group('calcularPinesDeshabilitados – frames 1-9', () {
    test('tiro 0: no disabled pins', () {
      final result = calcularPinesDeshabilitados(
        frame: 0,
        tiro: 0,
        pinesPorTiroFrame: _emptyTiros(),
      );
      expect(result, isEmpty);
    });

    test('tiro 1: tiro 0 pins are disabled', () {
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = [1, 2, 3];
      final result = calcularPinesDeshabilitados(
        frame: 2,
        tiro: 1,
        pinesPorTiroFrame: tiros,
      );
      expect(result, containsAll([1, 2, 3]));
      expect(result.length, 3);
    });
  });

  group('calcularPinesDeshabilitados – frame 10', () {
    test('tiro 0: no disabled pins', () {
      final result = calcularPinesDeshabilitados(
        frame: 9,
        tiro: 0,
        pinesPorTiroFrame: _emptyTiros(),
      );
      expect(result, isEmpty);
    });

    test('tiro 1 after strike: no disabled pins', () {
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = List.generate(10, (i) => i + 1);
      final result = calcularPinesDeshabilitados(
        frame: 9,
        tiro: 1,
        pinesPorTiroFrame: tiros,
      );
      expect(result, isEmpty);
    });

    test('tiro 1 after non-strike: tiro 0 pins disabled', () {
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = [1, 2, 3, 4, 5];
      final result = calcularPinesDeshabilitados(
        frame: 9,
        tiro: 1,
        pinesPorTiroFrame: tiros,
      );
      expect(result, containsAll([1, 2, 3, 4, 5]));
      expect(result.length, 5);
    });

    test('tiro 2 after two strikes: no disabled pins', () {
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = List.generate(10, (i) => i + 1);
      tiros[1] = List.generate(10, (i) => i + 1);
      final result = calcularPinesDeshabilitados(
        frame: 9,
        tiro: 2,
        pinesPorTiroFrame: tiros,
      );
      expect(result, isEmpty);
    });

    test('tiro 2 after strike + partial: second shot pins disabled', () {
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = List.generate(10, (i) => i + 1);
      tiros[1] = [1, 2, 3, 4, 5];
      final result = calcularPinesDeshabilitados(
        frame: 9,
        tiro: 2,
        pinesPorTiroFrame: tiros,
      );
      expect(result, containsAll([1, 2, 3, 4, 5]));
      expect(result.length, 5);
    });

    test('tiro 2 after spare: no disabled pins', () {
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = [1, 2, 3, 4, 5];
      tiros[1] = [6, 7, 8, 9, 10]; // spare
      final result = calcularPinesDeshabilitados(
        frame: 9,
        tiro: 2,
        pinesPorTiroFrame: tiros,
      );
      expect(result, isEmpty);
    });

    test('tiro 2 with no strike/spare: all prior pins disabled', () {
      final tiros = List<List<int>?>.filled(3, null);
      tiros[0] = [1, 2, 3];
      tiros[1] = [4, 5];
      final result = calcularPinesDeshabilitados(
        frame: 9,
        tiro: 2,
        pinesPorTiroFrame: tiros,
      );
      expect(result, containsAll([1, 2, 3, 4, 5]));
      expect(result.length, 5);
    });
  });
}
