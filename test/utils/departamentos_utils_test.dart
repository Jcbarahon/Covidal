import 'package:flutter_test/flutter_test.dart';
import 'package:covidal/utils/departamentos_utils.dart';

void main() {
  group('nextDepartamentoName', () {
    test('lista vacía devuelve A1/B1 según sección', () {
      expect(nextDepartamentoName([], 'A'), 'A1');
      expect(nextDepartamentoName([], 'b'), 'B1');
    });

    test('continúa desde el máximo existente', () {
      expect(nextDepartamentoName(['A1','A2','A5'], 'A'), 'A6');
    });

    test('ignora elementos de otras secciones', () {
      expect(nextDepartamentoName(['A1','B3','B10'], 'A'), 'A2');
      expect(nextDepartamentoName(['A1','B3','B10'], 'B'), 'B11');
    });

    test('tolera mayúsculas/minúsculas', () {
      expect(nextDepartamentoName(['a1','A2','a10'], 'a'), 'A11');
    });

    test('ignora nombres malformados', () {
      expect(nextDepartamentoName(['AX','A','A-2','A?','A3'], 'A'), 'A4');
    });
  });
}
