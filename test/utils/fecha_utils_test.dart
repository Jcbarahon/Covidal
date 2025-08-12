import 'package:flutter_test/flutter_test.dart';
import 'package:covidal/utils/fecha_utils.dart';



void main() {
  group('fecha_utils', () {
    test('mesEnTexto devuelve el nombre correcto', () {
      expect(mesEnTexto(1), 'enero');
      expect(mesEnTexto(12), 'diciembre');
    });

    test('mesEnTexto lanza error en meses inválidos', () {
      expect(() => mesEnTexto(0), throwsArgumentError);
      expect(() => mesEnTexto(13), throwsArgumentError);
    });

    test('formatoHora12 da 2:05 pm para 14:05', () {
      final dt = DateTime(2025, 8, 9, 14, 5);
      expect(formatoHora12(dt), '2:05 pm');
    });

    test('formatearFecha compone la frase completa', () {
      final dt = DateTime(2025, 8, 9, 14, 5);
      final out = formatearFecha(dt);
      expect(out.contains('9 de agosto de 2025'), isTrue);
      expect(out.contains('2:05 pm'), isTrue);
    });

    test('formatearFecha vacía si null', () {
      expect(formatearFecha(null), '');
    });
  });
}
