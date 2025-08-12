import 'package:flutter_test/flutter_test.dart';
import 'package:covidal/utils/edificio_utils.dart';

void main() {
  test('obtenerSiguienteNumeroDesdeNombres maneja lista vacía', () {
    expect(obtenerSiguienteNumeroDesdeNombres([]), 1);
  });

  test('obtiene el siguiente número mayor', () {
    final nombres = ['Terraza', 'Piso 1', 'Piso 3', 'Planta Baja'];
    expect(obtenerSiguienteNumeroDesdeNombres(nombres), 4);
  });

  test('ignora nombres que no matchean', () {
    final nombres = ['T', 'PB', 'Piso X', 'Piso 02', 'Piso 2'];
    expect(obtenerSiguienteNumeroDesdeNombres(nombres), 3);
  });

  test('funciona con espacios extra', () {
    final nombres = ['  Piso 5 ', 'Piso 1'];
    expect(obtenerSiguienteNumeroDesdeNombres(nombres), 6);
  });
}
