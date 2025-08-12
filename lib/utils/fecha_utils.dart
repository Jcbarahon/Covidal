// lib/utils/fecha_utils.dart
library fecha_utils;

String mesEnTexto(int mes) {
  const meses = [
    'enero','febrero','marzo','abril','mayo','junio',
    'julio','agosto','septiembre','octubre','noviembre','diciembre'
  ];
  if (mes < 1 || mes > 12) {
    throw ArgumentError('Mes fuera de rango: $mes');
  }
  return meses[mes - 1];
}

String formatoHora12(DateTime fecha) {
  final hora12 = fecha.hour % 12 == 0 ? 12 : fecha.hour % 12;
  final ampm = fecha.hour >= 12 ? 'pm' : 'am';
  final minutos = fecha.minute.toString().padLeft(2, '0'); // <— aquí el cambio
  return '$hora12:$minutos $ampm';
}

String formatearFecha(DateTime? fecha) {
  if (fecha == null) return '';
  return 'Última modificación: ${fecha.day} de ${mesEnTexto(fecha.month)} de ${fecha.year}, ${formatoHora12(fecha)}';
}
