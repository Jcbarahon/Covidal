import 'package:flutter_test/flutter_test.dart';
import 'package:covidal/utils/medidas_utils.dart'; 

void main() {
  test('Parsea filas y valida medidas', () {
    final filas = [
      {'alto': '1.2', 'ancho': '0.8'},
      {'alto': ' 1,5 ', 'ancho': ' 1 '}, // con coma decimal
      {'alto': '', 'ancho': '2'}, // inválida
    ];

    final medidas = parseMedidasDesdeMaps(filas);

    // Lista no es completamente válida porque hay una fila con alto vacío
    expect(listaCompletaValida(medidas), isFalse);

    // Primera medida: alto 1.2, ancho 0.8 → válida
    expect(medidas[0].esValida, isTrue);

    // Última medida: alto vacío → inválida
    expect(medidas.last.esValida, isFalse);
  });

  test('Determina estado del piso', () {
    // Caso: departamento actual inactivo
    expect(
      determinarEstadoPiso(
        totalDepartamentos: 6,
        departamentosConMedidas: 6,
        departamentosListos: 6,
        estadoSeleccionadoDepartamentoActual: 'inactivo',
      ),
      'inactivo',
    );

    // Caso: todos con medidas y listos
    expect(
      determinarEstadoPiso(
        totalDepartamentos: 3,
        departamentosConMedidas: 3,
        departamentosListos: 3,
        estadoSeleccionadoDepartamentoActual: 'activo',
      ),
      'listo',
    );

    // Caso: faltan medidas o listos
    expect(
      determinarEstadoPiso(
        totalDepartamentos: 4,
        departamentosConMedidas: 3,
        departamentosListos: 2,
        estadoSeleccionadoDepartamentoActual: 'activo',
      ),
      'activo',
    );
  });
}
