import 'package:cloud_firestore/cloud_firestore.dart';

class MedidasService {
  final FirebaseFirestore db;
  MedidasService({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  DocumentReference _medidasRef(String nombrePiso, String nombreDepartamento) {
    final pisoId = nombrePiso.toLowerCase().replaceAll(' ', '_');
    final depId  = nombreDepartamento.toLowerCase().replaceAll(' ', '_');
    return db
        .collection('edificios').doc('principal')
        .collection('pisos').doc(pisoId)
        .collection('departamentos').doc(depId)
        .collection('detalles').doc('medidas');
  }

  Future<void> guardarMedidasYActualizarPiso({
    required String nombrePiso,
    required String nombreDepartamento,
    required String estadoSeleccionado, // 'activo' | 'inactivo' | 'listo'
    required List<Map<String, dynamic>> aluminio,
    required List<Map<String, dynamic>> vidrio,
    required String observacionesAluminio,
    required String observacionesVidrio,
  }) async {
    final medidasRef = _medidasRef(nombrePiso, nombreDepartamento);

    await medidasRef.set({
      'estado': estadoSeleccionado,
      'aluminio':
          aluminio.map((e) => {'alto': e['alto'], 'ancho': e['ancho']}).toList(),
      'vidrio':
          vidrio.map((e) => {'alto': e['alto'], 'ancho': e['ancho']}).toList(),
      'observacionesAluminio': observacionesAluminio,
      'observacionesVidrio': observacionesVidrio,
      'fechaGuardado': FieldValue.serverTimestamp(),
    });

    final pisoId = nombrePiso.toLowerCase().replaceAll(' ', '_');
    final departamentosRef = db
        .collection('edificios').doc('principal')
        .collection('pisos').doc(pisoId)
        .collection('departamentos');

    String nuevoEstadoPiso;

    if (estadoSeleccionado == 'inactivo') {
      nuevoEstadoPiso = 'inactivo';
    } else {
      final departamentosSnapshot = await departamentosRef.get();
      int totalDepartamentos = 0;
      int listos = 0;
      int conMedidas = 0;

      for (final doc in departamentosSnapshot.docs) {
        final medidasDoc =
            await doc.reference.collection('detalles').doc('medidas').get();
        if (medidasDoc.exists) {
          final data = medidasDoc.data();
          if (data != null) {
            conMedidas++;
            if (data['estado'] == 'listo') {
              listos++;
            }
          }
        }
        totalDepartamentos++;
      }

      nuevoEstadoPiso = 'activo';
      if (totalDepartamentos > 0 &&
          conMedidas == totalDepartamentos &&
          listos == totalDepartamentos) {
        nuevoEstadoPiso = 'listo';
      }
    }

    await db
        .collection('edificios').doc('principal')
        .collection('pisos').doc(pisoId)
        .update({'estado': nuevoEstadoPiso});
  }

  Future<void> guardarSoloEstado({
    required String nombrePiso,
    required String nombreDepartamento,
    required String estadoSeleccionado,
    required List<Map<String, dynamic>> aluminio,
    required List<Map<String, dynamic>> vidrio,
    required String observacionesAluminio,
    required String observacionesVidrio,
  }) async {
    final medidasRef = _medidasRef(nombrePiso, nombreDepartamento);

    await medidasRef.set({
      'estado': estadoSeleccionado,
      'aluminio':
          aluminio.map((e) => {'alto': e['alto'], 'ancho': e['ancho']}).toList(),
      'vidrio':
          vidrio.map((e) => {'alto': e['alto'], 'ancho': e['ancho']}).toList(),
      'observacionesAluminio': observacionesAluminio,
      'observacionesVidrio': observacionesVidrio,
      'fechaGuardado': FieldValue.serverTimestamp(),
    });

    final pisoId = nombrePiso.toLowerCase().replaceAll(' ', '_');
    final departamentosRef = db
        .collection('edificios').doc('principal')
        .collection('pisos').doc(pisoId)
        .collection('departamentos');

    final departamentosSnapshot = await departamentosRef.get();
    int totalDepartamentos = 0;
    int listos = 0;
    int conMedidas = 0;

    for (final doc in departamentosSnapshot.docs) {
      final medidasDoc =
          await doc.reference.collection('detalles').doc('medidas').get();
      if (medidasDoc.exists) {
        final data = medidasDoc.data();
        if (data != null) {
          conMedidas++;
          if (data['estado'] == 'listo') listos++;
        }
      }
      totalDepartamentos++;
    }

    String nuevoEstadoPiso;
    if (estadoSeleccionado == 'inactivo') {
      nuevoEstadoPiso = 'inactivo';
    } else {
      nuevoEstadoPiso = 'activo';
      if (totalDepartamentos > 0 &&
          conMedidas == totalDepartamentos &&
          listos == totalDepartamentos) {
        nuevoEstadoPiso = 'listo';
      }
    }

    await db
        .collection('edificios').doc('principal')
        .collection('pisos').doc(pisoId)
        .update({'estado': nuevoEstadoPiso});
  }
}
