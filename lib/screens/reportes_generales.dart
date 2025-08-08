import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:open_file/open_file.dart';

class ReportesGeneralesPage extends StatefulWidget {
  const ReportesGeneralesPage({Key? key}) : super(key: key);

  @override
  State<ReportesGeneralesPage> createState() => _ReportesGeneralesPageState();
}

Future<void> generarExcelAluminio(String piso) async {
  final firestore = FirebaseFirestore.instance;
  final pisoId = piso.toLowerCase().replaceAll(' ', '_');

  final departamentosSnapshot =
      await firestore
          .collection('edificios')
          .doc('principal')
          .collection('pisos')
          .doc(pisoId)
          .collection('departamentos')
          .get();

  final excel = Excel.createExcel();
  // Eliminar hoja por defecto "Sheet1"

  final Sheet sheet = excel['Sheet1'];

  // Escribir encabezados
  sheet.appendRow(['Departamento', 'Medida #', 'Campo', 'Valor']);

  for (var departamentoDoc in departamentosSnapshot.docs) {
    final departamentoId = departamentoDoc.id;

    final detallesDoc =
        await firestore
            .collection('edificios')
            .doc('principal')
            .collection('pisos')
            .doc(pisoId)
            .collection('departamentos')
            .doc(departamentoId)
            .collection('detalles')
            .doc('medidas')
            .get();

    if (!detallesDoc.exists) {
      sheet.appendRow([departamentoId, '-', 'Alto', '-']);
      sheet.appendRow([departamentoId, '-', 'Ancho', '-']);
      continue;
    }

    final data = detallesDoc.data() ?? {};
    final List<dynamic>? aluminioList = data['aluminio'];

    if (aluminioList != null && aluminioList.isNotEmpty) {
      for (int i = 0; i < aluminioList.length; i++) {
        final aluminio = aluminioList[i] as Map<String, dynamic>;

        final alto = aluminio['alto']?.toString() ?? '-';
        final ancho = aluminio['ancho']?.toString() ?? '-';

        sheet.appendRow([departamentoId, (i + 1).toString(), 'Alto', alto]);
        sheet.appendRow([departamentoId, (i + 1).toString(), 'Ancho', ancho]);
      }
    } else {
      sheet.appendRow([departamentoId, '-', 'Alto', '-']);
      sheet.appendRow([departamentoId, '-', 'Ancho', '-']);
    }
  }

  // Guardar archivo en carpeta temporal
  final outputDir = await getTemporaryDirectory();
  final filePath = '${outputDir.path}/reporte_aluminio_$pisoId.xlsx';

  final fileBytes = excel.encode();
  if (fileBytes == null) {
    print('Error al generar archivo Excel');
    return;
  }

  final file = File(filePath);
  await file.writeAsBytes(fileBytes);

  print('Archivo Excel generado en: $filePath');

  // Abrir archivo automáticamente
  await OpenFile.open(
    filePath,
  ); // Aquí puedes abrir o compartir el archivo con paquetes adicionales si quieres
}

Future<void> generarPdfAluminio(String piso) async {
  final firestore = FirebaseFirestore.instance;
  final pisoId = piso.toLowerCase().replaceAll(' ', '_');

  final departamentosSnapshot =
      await firestore
          .collection('edificios')
          .doc('principal')
          .collection('pisos')
          .doc(pisoId)
          .collection('departamentos')
          .get();

  final List<List<String>> filas = [];
  filas.add([
    'Departamento',
    'Medida #',
    'Campo',
    'Valor',
  ]); // Añadí columna índice

  for (var departamentoDoc in departamentosSnapshot.docs) {
    final departamentoId = departamentoDoc.id;

    final detallesDoc =
        await firestore
            .collection('edificios')
            .doc('principal')
            .collection('pisos')
            .doc(pisoId)
            .collection('departamentos')
            .doc(departamentoId)
            .collection('detalles')
            .doc('medidas')
            .get();

    if (!detallesDoc.exists) {
      filas.add([departamentoId, '-', 'Alto', '-']);
      filas.add([departamentoId, '-', 'Ancho', '-']);
      continue;
    }

    final data = detallesDoc.data() ?? {};
    final List<dynamic>? aluminioList = data['aluminio'];

    if (aluminioList != null && aluminioList.isNotEmpty) {
      for (int i = 0; i < aluminioList.length; i++) {
        final aluminio = aluminioList[i] as Map<String, dynamic>;

        final alto = aluminio['alto']?.toString() ?? '-';
        final ancho = aluminio['ancho']?.toString() ?? '-';

        filas.add([departamentoId, (i + 1).toString(), 'Alto', alto]);
        filas.add([departamentoId, (i + 1).toString(), 'Ancho', ancho]);
      }
    } else {
      filas.add([departamentoId, '-', 'Alto', '-']);
      filas.add([departamentoId, '-', 'Ancho', '-']);
    }
  }

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Reporte de Aluminio - $piso',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              data: filas,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        );
      },
    ),
  );

  final output = await getTemporaryDirectory();
  final file = File("${output.path}/reporte_aluminio_$pisoId.pdf");
  await file.writeAsBytes(await pdf.save());

  await Printing.layoutPdf(onLayout: (format) => pdf.save());
}

class _ReportesGeneralesPageState extends State<ReportesGeneralesPage> {
  List<String> pisos = [];
  String? pisoAluminio;
  String? pisoVidrio;

  @override
  void initState() {
    super.initState();
    cargarPisosDesdeFirestore();
    getDepartamentos("piso_4");
  }

  Future<void> cargarPisosDesdeFirestore() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('edificios')
              .doc('principal') // Cambia si usas otro ID
              .collection('pisos')
              .orderBy(
                'orden',
              ) // opcional, para ordenar por campo orden si tienes
              .get();

      final listaPisos =
          snapshot.docs.map((doc) => doc['nombre'] as String).toList();

      setState(() {
        pisos = listaPisos;
        // Si no hay selección previa, asignar el primer piso
        if (pisos.isNotEmpty) {
          pisoAluminio ??= pisos[0];
          pisoVidrio ??= pisos[0];
        }
      });
    } catch (e) {
      print('Error cargando pisos desde Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String fechaHoy =
        DateFormat(
          'EEEE dd/MM/yyyy',
          'es',
        ).format(DateTime.now()).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF098CD1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF098CD1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          'Reportes Generales',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                fechaHoy,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFD9D9D9), thickness: 10),
          _buildSeccion(
            titulo: 'Aluminio',
            pisoSeleccionado: pisoAluminio,
            pisos: pisos,
            onPisoChanged: (valor) {
              setState(() {
                pisoAluminio = valor;
              });
            },
          ),
          const Divider(color: Color(0xFFD9D9D9), thickness: 10),
          _buildSeccion(
            titulo: 'Vidrio',
            pisoSeleccionado: pisoVidrio,
            pisos: pisos,
            onPisoChanged: (valor) {
              setState(() {
                pisoVidrio = valor;
              });
            },
          ),
          const Divider(color: Color(0xFFD9D9D9), thickness: 10),
          const Spacer(),
          Column(
            children: [
              const Divider(color: Color(0xFFD9D9D9), thickness: 10),
              Image.asset('assets/images/Logo.png', height: 80),
              const SizedBox(height: 2),
              Container(
                height: 20,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromARGB(255, 37, 150, 211),
                      Color(0xFFE04747), // rosado-lila abajo
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion({
    required String titulo,
    required String? pisoSeleccionado,
    required List<String> pisos,
    required ValueChanged<String?> onPisoChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: pisoSeleccionado,
                  hint: const Text("Seleccionar piso"),
                  dropdownColor: Colors.white,
                  iconEnabledColor: Colors.black,
                  underline: Container(),
                  style: const TextStyle(color: Colors.black),
                  items:
                      pisos
                          .map(
                            (piso) => DropdownMenuItem(
                              value: piso,
                              child: Text(piso),
                            ),
                          )
                          .toList(),
                  onChanged: onPisoChanged,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  if (pisoAluminio != null) {
                    await generarExcelAluminio(pisoAluminio!);
                  } else {
                    // Opcional: mostrar mensaje que no hay piso seleccionado
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Por favor selecciona un piso.')),
                    );
                  }
                },
                child: Image.asset('assets/images/excel.png', height: 40),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  if (pisoAluminio != null) {
                    await generarPdfAluminio(pisoAluminio!);
                  } else {
                    // Opcional: mostrar mensaje que no hay piso seleccionado
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Por favor selecciona un piso.')),
                    );
                  }
                },
                child: Image.asset('assets/images/pdf.png', height: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> getDepartamentos(String nombrePiso) async {
  try {
    final departamentosRef = FirebaseFirestore.instance
        .collection('edificios')
        .doc('principal')
        .collection('pisos')
        .doc(nombrePiso) // Ej: piso_4
        .collection('departamentos');

    final snapshot = await departamentosRef.get();

    if (snapshot.docs.isEmpty) {
      print('⚠️ No se encontraron departamentos en $nombrePiso');
    } else {
      for (var doc in snapshot.docs) {
        print('✅ Departamento: ${doc.id}');
      }
    }
  } catch (e) {
    print('❌ Error al obtener departamentos de $nombrePiso: $e');
  }
}
