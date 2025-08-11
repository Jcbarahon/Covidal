library departamentos_utils;

/// Dada una lista de nombres de una sección (p.ej. ['A1','A3'])
/// devuelve el siguiente nombre incremental (p.ej. 'A4').
String nextDepartamentoName(List<String> existentes, String seccion) {
  final prefix = seccion.toUpperCase();
  int maxN = 0;
  for (final dep in existentes) {
    if (dep.toUpperCase().startsWith(prefix)) {
      final numStr = dep.substring(prefix.length);
      final n = int.tryParse(numStr) ?? 0;
      if (n > maxN) maxN = n;
    }
  }
  return '$prefix${maxN + 1}';
}
