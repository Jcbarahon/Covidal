library medidas_utils;

class Medida {
  final double? alto;
  final double? ancho;
  const Medida({required this.alto, required this.ancho});

  factory Medida.fromStrings(String altoStr, String anchoStr) {
    double? toD(String s) {
      final t = s.trim();
      if (t.isEmpty) return null;
      return double.tryParse(t.replaceAll(',', '.')); // admite coma decimal
    }
    return Medida(alto: toD(altoStr), ancho: toD(anchoStr));
  }

  bool get esValida =>
      (alto != null && ancho != null && alto! > 0 && ancho! > 0);

  Map<String, dynamic> toMapStrings() => {
        'alto': alto?.toString() ?? '',
        'ancho': ancho?.toString() ?? '',
      };
}

List<Medida> parseMedidasDesdeMaps(List<Map<String, dynamic>> filas) {
  return filas.map((e) {
    final alto = (e['alto'] ?? '').toString();
    final ancho = (e['ancho'] ?? '').toString();
    return Medida.fromStrings(alto, ancho);
  }).toList();
}

bool listaCompletaValida(List<Medida> medidas) {
  if (medidas.isEmpty) return false;
  return medidas.every((m) => m.esValida);
}

String determinarEstadoPiso({
  required int totalDepartamentos,
  required int departamentosConMedidas,
  required int departamentosListos,
  required String estadoSeleccionadoDepartamentoActual, // 'activo' | 'inactivo' | 'listo'
}) {
  if (estadoSeleccionadoDepartamentoActual == 'inactivo') return 'inactivo';
  if (totalDepartamentos <= 0) return 'activo';
  final todosTienenMedidas =
      departamentosConMedidas == totalDepartamentos;
  final todosListos =
      departamentosListos == totalDepartamentos;
  if (todosTienenMedidas && todosListos) return 'listo';
  return 'activo';
}
