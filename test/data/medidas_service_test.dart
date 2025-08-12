import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:covidal/data/medidas_service.dart'; // <- ajusta el import

void main() {
  test('Guarda medidas y muestra evidencia del doc y del estado del piso', () async {
    // Arrange: DB falsa + servicio
    final fake = FakeFirebaseFirestore();
    final service = MedidasService(firestore: fake);

    // Prepara piso y depto (como existirían en tu app)
    await fake.collection('edificios').doc('principal')
      .collection('pisos').doc('piso_1')
      .set({'nombre': 'Piso 1', 'estado': 'inactivo', 'orden': 1});

    await fake.collection('edificios').doc('principal')
      .collection('pisos').doc('piso_1')
      .collection('departamentos').doc('a1')
      .set({'nombre': 'A1'});

    // Datos simulando lo que ingresa el usuario en la UI
    final aluminio = [
      {'alto': '1.2', 'ancho': '0.8'},
      {'alto': '1,5', 'ancho': '1'},
    ];
    final vidrio = [
      {'alto': '2', 'ancho': '1.1'},
    ];

    // Act: guardar usando la misma lógica que tu app (pero en el servicio)
    await service.guardarMedidasYActualizarPiso(
      nombrePiso: 'Piso 1',
      nombreDepartamento: 'A1',
      estadoSeleccionado: 'inactivo', // igual que tu estado inicial
      aluminio: aluminio,
      vidrio: vidrio,
      observacionesAluminio: 'Obs Alu',
      observacionesVidrio: 'Obs Vid',
    );

    // Assert + Evidencia: leemos lo guardado y lo imprimimos
    final docMedidas = await fake.collection('edificios').doc('principal')
      .collection('pisos').doc('piso_1')
      .collection('departamentos').doc('a1')
      .collection('detalles').doc('medidas')
      .get();

    expect(docMedidas.exists, isTrue);

    final data = docMedidas.data()!;
    // Imprime JSON completo del documento de medidas
    // Esto lo verás en la consola al correr `flutter test`
    // para defender la prueba con evidencia explícita.
    // (En entorno CI también queda en logs)
    // -------------------------------------------------
    // Evidencia 1: documento de medidas
    print('📄 Documento medidas guardado: ${data}');
    // -------------------------------------------------

    expect(data['estado'], 'inactivo');
    expect((data['aluminio'] as List).length, 2);
    expect((data['vidrio']   as List).length, 1);
    expect(data['observacionesAluminio'], 'Obs Alu');
    expect(data['observacionesVidrio'], 'Obs Vid');

    // Verifica y muestra el estado final del piso
    final pisoSnap = await fake.collection('edificios').doc('principal')
      .collection('pisos').doc('piso_1').get();
    final estadoPiso = pisoSnap.data()!['estado'];

    // -------------------------------------------------
    // Evidencia 2: estado del piso tras el guardado
    print('🏢 Estado del piso después de guardar: $estadoPiso');
    // -------------------------------------------------

    expect(estadoPiso, 'inactivo'); // prioridad por estado depto actual
  });
}
