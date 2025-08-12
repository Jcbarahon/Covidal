library edificio_utils;

/// A partir de una lista de nombres (incluyendo "Piso N", "Terraza", "Planta Baja"),
/// retorna el próximo número entero para generar "Piso {N+1}".
int obtenerSiguienteNumeroDesdeNombres(Iterable<String> nombres) {
  final regex = RegExp(r'^Piso (\d+)$');
  int maxN = 0;
  for (final n in nombres) {
    final m = regex.firstMatch(n.trim());
    if (m != null) {
      final val = int.parse(m.group(1)!);
      if (val > maxN) maxN = val;
    }
  }
  return maxN + 1; // si no hay pisos, regresa 1
}
