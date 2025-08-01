import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedidasDepartamentoPage extends StatefulWidget {
  final String nombrePiso;
  final String nombreDepartamento;

  const MedidasDepartamentoPage({
    super.key,
    required this.nombrePiso,
    required this.nombreDepartamento,
  });

  @override
  State<MedidasDepartamentoPage> createState() =>
      _MedidasDepartamentoPageState();
}

class _MedidasDepartamentoPageState extends State<MedidasDepartamentoPage> {
  List<Map<String, dynamic>> aluminio = [
    {'alto': '', 'ancho': '', 'editable': true},
  ];
  List<Map<String, dynamic>> vidrio = [
    {'alto': '', 'ancho': '', 'editable': true},
  ];

  final observacionesAluminio = TextEditingController();
  final observacionesVidrio = TextEditingController();

  String estadoSeleccionado = 'inactivo'; // Estado inicial
  bool _guardadoReciente = true;
  bool _cargandoDatos = false;
  DateTime? _ultimaModificacion; // 🚨 NUEVA VARIABLE

  DocumentReference get _medidasRef {
    final pisoId = widget.nombrePiso.toLowerCase().replaceAll(' ', '_');
    final departamentoId = widget.nombreDepartamento.toLowerCase().replaceAll(
      ' ',
      '_',
    );
    return FirebaseFirestore.instance
        .collection('edificios')
        .doc('principal')
        .collection('pisos')
        .doc(pisoId)
        .collection('departamentos')
        .doc(departamentoId)
        .collection('detalles')
        .doc('medidas');
  }

  bool _hayCambiosNoGuardados() {
    return !_guardadoReciente; // NUEVO 🚨
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '';
    return 'Última modificación: ${fecha.day} de ${_mesEnTexto(fecha.month)} de ${fecha.year}, ${_formatoHora(fecha)}';
  }

  String _mesEnTexto(int mes) {
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return meses[mes - 1];
  }

  String _formatoHora(DateTime fecha) {
    final hora = fecha.hour > 12 ? fecha.hour - 12 : fecha.hour;
    final ampm = fecha.hour >= 12 ? 'pm' : 'am';
    final minutos = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minutos $ampm';
  }

  @override
  void initState() {
    super.initState();
    _cargarMedidas();
    observacionesAluminio.addListener(() {
      if (!_cargandoDatos) {
        _guardadoReciente = false;
      }
    });

    observacionesVidrio.addListener(() {
      if (!_cargandoDatos) {
        _guardadoReciente = false;
      }
    });
  }

  @override
  void dispose() {
    observacionesAluminio.dispose();
    observacionesVidrio.dispose();
    super.dispose();
  }

  Future<void> _cargarMedidas() async {
    _cargandoDatos = true;
    final doc = await _medidasRef.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        estadoSeleccionado = data['estado'] ?? 'inactivo';
        aluminio = List<Map<String, dynamic>>.from(
          (data['aluminio'] as List).map(
            (e) => {...Map<String, dynamic>.from(e), 'editable': false},
          ),
        );
        vidrio = List<Map<String, dynamic>>.from(
          (data['vidrio'] as List).map(
            (e) => {...Map<String, dynamic>.from(e), 'editable': false},
          ),
        );
        observacionesAluminio.text = data['observacionesAluminio'] ?? '';
        observacionesVidrio.text = data['observacionesVidrio'] ?? '';

        // 🚨 NUEVO: obtenemos la fecha del campo 'fechaGuardado'
        final Timestamp? fecha = data['fechaGuardado'];
        _ultimaModificacion = fecha?.toDate();

        _guardadoReciente = true;
      });
    }
    _cargandoDatos = false;
  }

  Future<void> _guardarMedidasYActualizarPiso() async {
    setState(() {
      for (var fila in aluminio) {
        fila['editable'] = false;
      }
      for (var fila in vidrio) {
        fila['editable'] = false;
      }
    });

    try {
      await _medidasRef.set({
        'estado': estadoSeleccionado,
        'aluminio':
            aluminio
                .map((e) => {'alto': e['alto'], 'ancho': e['ancho']})
                .toList(),
        'vidrio':
            vidrio
                .map((e) => {'alto': e['alto'], 'ancho': e['ancho']})
                .toList(),
        'observacionesAluminio': observacionesAluminio.text,
        'observacionesVidrio': observacionesVidrio.text,
        'fechaGuardado': FieldValue.serverTimestamp(),
      });
      setState(() {
        _guardadoReciente = true; // NUEVO 🚨
      });

      final pisoId = widget.nombrePiso.toLowerCase().replaceAll(' ', '_');
      final departamentosRef = FirebaseFirestore.instance
          .collection('edificios')
          .doc('principal')
          .collection('pisos')
          .doc(pisoId)
          .collection('departamentos');

      String nuevoEstadoPiso;

      if (estadoSeleccionado == 'inactivo') {
        // Si lo pones manualmente en inactivo, respetamos eso.
        nuevoEstadoPiso = 'inactivo';
      } else {
        // Si es activo o listo, aplicamos lógica normal.
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
        if (conMedidas == totalDepartamentos && listos == totalDepartamentos) {
          nuevoEstadoPiso = 'listo';
        }
      }

      await FirebaseFirestore.instance
          .collection('edificios')
          .doc('principal')
          .collection('pisos')
          .doc(pisoId)
          .update({'estado': nuevoEstadoPiso});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardado y estado del piso actualizado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  Future<void> _guardarSoloEstado() async {
    try {
      await _medidasRef.set({
        'estado': estadoSeleccionado,
        'aluminio':
            aluminio
                .map((e) => {'alto': e['alto'], 'ancho': e['ancho']})
                .toList(),
        'vidrio':
            vidrio
                .map((e) => {'alto': e['alto'], 'ancho': e['ancho']})
                .toList(),

        'observacionesAluminio': observacionesAluminio.text,
        'observacionesVidrio': observacionesVidrio.text,
        'fechaGuardado': FieldValue.serverTimestamp(),
      });

      setState(() {
        _guardadoReciente = true; // NUEVO 🚨
      });

      // Lógica para actualizar estado del piso igual que antes
      final pisoId = widget.nombrePiso.toLowerCase().replaceAll(' ', '_');
      final departamentosRef = FirebaseFirestore.instance
          .collection('edificios')
          .doc('principal')
          .collection('pisos')
          .doc(pisoId)
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
            if (data['estado'] == 'listo') {
              listos++;
            }
          }
        }
        totalDepartamentos++;
      }

      String nuevoEstadoPiso;

      // Si seleccionas "inactivo", forzar el estado del piso como inactivo también
      if (estadoSeleccionado == 'inactivo') {
        nuevoEstadoPiso = 'inactivo';
      } else {
        nuevoEstadoPiso = 'activo';
        if (conMedidas == totalDepartamentos && listos == totalDepartamentos) {
          nuevoEstadoPiso = 'listo';
        }
      }

      await FirebaseFirestore.instance
          .collection('edificios')
          .doc('principal')
          .collection('pisos')
          .doc(pisoId)
          .update({'estado': nuevoEstadoPiso});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado "$estadoSeleccionado" guardado correctamente'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar estado: $e')));
    }
  }

  void _agregarFila(List<Map<String, dynamic>> lista) {
    setState(() {
      lista.add({'alto': '', 'ancho': '', 'editable': true});
      _guardadoReciente = false; // NUEVO 🚨
    });
  }

  void _eliminarFila(List<Map<String, dynamic>> lista, int index) {
    setState(() {
      _guardadoReciente = false; // NUEVO 🚨
      if (lista.length > 1) {
        lista.removeAt(index);
      } else {
        lista[0]['alto'] = '';
        lista[0]['ancho'] = '';
        lista[0]['editable'] = true;
      }
    });
  }

  Widget _buildEstadoButton({
    required String estado,
    required String icono,
    required String texto,
  }) {
    final bool esSeleccionado = estadoSeleccionado == estado;

    return GestureDetector(
      onTap: () async {
        setState(() {
          estadoSeleccionado = estado;
        });
        await _guardarSoloEstado();
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color:
                    esSeleccionado
                        ? const Color.fromARGB(255, 206, 16, 16)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color.fromARGB(255, 218, 17, 17),
                  width: esSeleccionado ? 2 : 1,
                ),
              ),
              child: Image.asset('assets/images/$icono', height: 28),
            ),
            const SizedBox(height: 2),
            Text(
              texto,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    esSeleccionado ? FontWeight.bold : FontWeight.normal,
                decoration: esSeleccionado ? TextDecoration.underline : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampo({
    required String initialValue,
    required Function(String) onChanged,
    required bool editable,
  }) {
    final controller = TextEditingController(text: initialValue);
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(10),
        color: editable ? Colors.white : Colors.grey[300],
      ),
      child: TextField(
        controller: controller,
        onChanged:
            editable
                ? (val) {
                  onChanged(val);
                  _guardadoReciente = false; // NUEVO 🚨
                }
                : null,
        enabled: editable,
        decoration: const InputDecoration(
          hintText: '...................',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFila(int index, List<Map<String, dynamic>> lista) {
    final fila = lista[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('${index + 1}', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: _buildCampo(
              initialValue: fila['alto']!,
              onChanged: (val) => fila['alto'] = val,
              editable: fila['editable']!,
            ),
          ),
          const SizedBox(width: 5),
          const Text('X'),
          const SizedBox(width: 5),
          Expanded(
            child: _buildCampo(
              initialValue: fila['ancho']!,
              onChanged: (val) => fila['ancho'] = val,
              editable: fila['editable']!,
            ),
          ),
          const SizedBox(width: 20),
          AnimatedScaleButton(
            onTap: () {
              setState(() {
                fila['editable'] = true;
              });
            },
            child: Image.asset('assets/images/editar.png', height: 26),
          ),
          const SizedBox(width: 20),
          AnimatedScaleButton(
            onTap: () => _eliminarFila(lista, index),
            child: Image.asset('assets/images/eliminar.png', height: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion({
    required String titulo,
    required List<Map<String, dynamic>> lista,
    required VoidCallback onAgregar,
    required VoidCallback onGuardar,
    required TextEditingController observacionesController,
    required String iconoAgregar,
    required Color fondo,
  }) {
    return Container(
      color: fondo,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: const Color(0xFFD9D9D9),
                  child: Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedScaleButton(
                onTap: onGuardar,
                child: Column(
                  children: [
                    Image.asset('assets/images/guardar.png', height: 36),
                    const SizedBox(height: 4),
                    const Text('Guardar', style: TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(lista.length, (index) {
            return _buildFila(index, lista);
          }),
          const SizedBox(height: 20),
          Center(
            child: AnimatedScaleButton(
              onTap: onAgregar,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 133, 163, 188),
                  border: Border.all(
                    color: const Color.fromARGB(255, 180, 50, 50),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/$iconoAgregar', height: 30),
                    const SizedBox(height: 4),
                    const Text(
                      'Añadir',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Observaciones', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Container(
            height: 47.6,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: TextField(
              controller: observacionesController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration.collapsed(
                hintText:
                    '..................................................................',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: const Color(0xFFD9D9D9),
                padding: const EdgeInsets.only(
                  left: 10,
                  right: 12,
                  top: 40,
                  bottom: 4,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () async {
                        if (_hayCambiosNoGuardados()) {
                          final salir = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Cambios no guardados'),
                                  content: const Text(
                                    'Tienes cambios sin guardar. ¿Estás seguro que quieres salir?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(context).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(true),
                                      child: const Text('Salir'),
                                    ),
                                  ],
                                ),
                          );
                          if (salir == true) {
                            Navigator.pop(context);
                          }
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        Text(
                          '${widget.nombrePiso} - ${widget.nombreDepartamento}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatearFecha(_ultimaModificacion),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSeccion(
                        titulo: 'Aluminio',
                        lista: aluminio,
                        onAgregar: () => _agregarFila(aluminio),
                        onGuardar: _guardarMedidasYActualizarPiso,
                        observacionesController: observacionesAluminio,
                        iconoAgregar: 'aluminio.png',
                        fondo: const Color.fromARGB(217, 221, 221, 221),
                      ),
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        child: _buildSeccion(
                          titulo: 'Vidrio',
                          lista: vidrio,
                          onAgregar: () => _agregarFila(vidrio),
                          onGuardar: _guardarMedidasYActualizarPiso,
                          observacionesController: observacionesVidrio,
                          iconoAgregar: 'vidrio.png',
                          fondo: const Color(0xFF7EC4FA),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 24,
            child: Container(color: const Color(0xFF7EC4FA)),
          ),
        ],
      ),
      bottomNavigationBar: Transform.translate(
        offset: const Offset(0, -20),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: Container(
            color: Colors.white,
            child: NavigationBar(
              height: 60,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 2,
              selectedIndex: [
                'activo',
                'inactivo',
                'listo',
              ].indexOf(estadoSeleccionado),

              destinations: [
                _buildEstadoButton(
                  estado: 'activo',
                  icono: 'activo.png',
                  texto: 'activo',
                ),
                _buildEstadoButton(
                  estado: 'inactivo',
                  icono: 'inactivo.png',
                  texto: 'inactivo',
                ),
                _buildEstadoButton(
                  estado: 'listo',
                  icono: 'listo.png',
                  texto: 'listo',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedScaleButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(_) => setState(() => _scale = 0.92);
  void _onTapUp(_) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}
