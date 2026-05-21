import 'package:bolometro/utils/app_constants.dart';
import 'package:bolometro/utils/registro_tiros_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatearTiroParaMostrar', () {
    test('muestra los fallos como guion', () {
      expect(formatearTiroParaMostrar('0'), AppConstants.simboloFallo);
    });

    test('mantiene otros valores válidos', () {
      expect(formatearTiroParaMostrar('x'), AppConstants.simboloStrike);
      expect(formatearTiroParaMostrar('/'), AppConstants.simboloSpare);
      expect(formatearTiroParaMostrar('8'), '8');
      expect(formatearTiroParaMostrar(''), isEmpty);
    });
  });
}
