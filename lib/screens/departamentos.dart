// ... tus imports
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'medidas_departamento.dart';

class DepartamentosPage extends StatefulWidget {
  final String nombrePiso;
  const DepartamentosPage({required this.nombrePiso, super.key});

  @override
  State<DepartamentosPage> createState() => _DepartamentosPageState();
}

class _DepartamentosPageState extends State<DepartamentosPage> {
  List<String> seccionA = [];
  List<String> seccionB = [];
  String? seleccionado;
  bool _hayCambios = false;

  @override
  void initState() {
    super.initState();
    _cargarDepartamentos();
  }

  Future<void> _cargarDepartamentos() async {
    final ref = FirebaseFirestore.instance
        .collection('edificios')
        .doc('principal')
        .collection('pisos')
        .doc(widget.nombrePiso.toLowerCase().replaceAll(' ', '_'))
        .collection('departamentos');

    final snapshot = await ref.get();

    List<String> a = [];
    List<String> b = [];

    for (var doc in snapshot.docs) {
      final nombre = doc.data()['nombre'] ?? '';
      if (nombre.startsWith('A')) {
        a.add(nombre);
      } else if (nombre.startsWith('B')) {
        b.add(nombre);
      }
    }

    setState(() {
      seccionA = a;
      seccionB = b;
    });
  }

  void _agregarDepartamento(String seccion) {
    setState(() {
      final lista = seccion == 'A' ? seccionA : seccionB;

      // Obtener el mayor número actual en la lista
      int maxNumero = 0;
      for (var dep in lista) {
        final numero = int.tryParse(dep.replaceAll(seccion, '')) ?? 0;
        if (numero > maxNumero) {
          maxNumero = numero;
        }
      }

      final nuevoNombre = '$seccion${maxNumero + 1}';
      lista.add(nuevoNombre);
      _hayCambios = true;
    });
  }

  void _eliminarDepartamento() async {
    if (seleccionado == null) return;

    final confirmacion = await _mostrarDialogoConfirmacion(
      'Confirmar eliminación',
      '¿Estás seguro de eliminar el departamento "$seleccionado"?',
    );

    if (confirmacion == true) {
      setState(() {
        seccionA.remove(seleccionado);
        seccionB.remove(seleccionado);
        seleccionado = null;
        _hayCambios = true;
      });
    } else {
      setState(() {
        seleccionado = null;
      });
    }
  }

  Future<void> _guardarDepartamentos() async {
    final ref = FirebaseFirestore.instance
        .collection('edificios')
        .doc('principal')
        .collection('pisos')
        .doc(widget.nombrePiso.toLowerCase().replaceAll(' ', '_'))
        .collection('departamentos');

    final snapshot = await ref.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    final todos = [...seccionA, ...seccionB];
    for (var nombre in todos) {
      await ref.doc(nombre.toLowerCase()).set({'nombre': nombre});
    }

    setState(() => _hayCambios = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Departamentos guardados')));
  }

  Future<bool> _mostrarDialogoConfirmacion(
    String titulo,
    String contenido,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(titulo),
                content: Text(contenido),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _confirmarSalir(VoidCallback accion) async {
    if (_hayCambios) {
      final salir = await _mostrarDialogoConfirmacion(
        'Cambios sin guardar',
        'Tienes cambios sin guardar. ¿Deseas guardarlos antes de salir?',
      );

      if (salir) {
        await _guardarDepartamentos();
      }
    }
    accion();
  }

  Widget _buildDepartamento(String nombre) {
    final esSeleccionado = nombre == seleccionado;

    return AnimatedScaleButton(
      onTap: () {
        if (esSeleccionado) {
          setState(() => seleccionado = null);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => MedidasDepartamentoPage(
                    nombrePiso: widget.nombrePiso,
                    nombreDepartamento: nombre,
                  ),
            ),
          );
        }
      },
      onLongPress: () {
        setState(() {
          seleccionado = esSeleccionado ? null : nombre;
        });
      },
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient:
              esSeleccionado
                  ? const LinearGradient(
                    colors: [Color(0xFFE04747), Color(0xFFB53636)],
                  )
                  : const LinearGradient(
                    colors: [Color(0xFF84BAE7), Color(0xFF008CFF)],
                  ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: esSeleccionado ? Colors.red.shade200 : Colors.black12,
            width: 1,
          ),
        ),
        child: Text(
          nombre,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: esSeleccionado ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildBotonAgregar(String seccion) {
    return AnimatedScaleButton(
      onTap: () => _agregarDepartamento(seccion),
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black26),
        ),
        child: const Icon(Icons.add, size: 28, color: Colors.black),
      ),
    );
  }

  Widget _buildSeccion(
    String titulo,
    List<String> departamentos,
    String seccion,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 1),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 0.01),
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            titulo.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...departamentos.map(_buildDepartamento).toList(),
            _buildBotonAgregar(seccion),
          ],
        ),
        const SizedBox(height: 10),
        Container(height: 2, color: Colors.grey.shade300),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF098CD1), Color(0xFFE04747)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed:
                            () => _confirmarSalir(() {
                              Navigator.pop(context);
                            }),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.nombrePiso,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const Text(
                          'Departamentos',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSeccion('A', seccionA, 'A'),
                      _buildSeccion('B', seccionB, 'B'),
                    ],
                  ),
                ),
              ),
              NavigationBarAcciones(
                onEliminar: _eliminarDepartamento,
                onGuardar: _guardarDepartamentos,
                onInicio:
                    () => _confirmarSalir(() {
                      Navigator.pushReplacementNamed(context, '/home');
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Aquí abajo no hay cambios en tus widgets auxiliares ---
class NavigationBarAcciones extends StatelessWidget {
  final VoidCallback onEliminar;
  final VoidCallback onGuardar;
  final VoidCallback onInicio;

  const NavigationBarAcciones({
    super.key,
    required this.onEliminar,
    required this.onGuardar,
    required this.onInicio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 95,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 218, 169, 169),
            Color.fromARGB(255, 135, 175, 236),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 0.01, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _AnimatedButton(
            onTap: onEliminar,
            child: Row(
              children: [
                const Text(
                  'Eliminar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Image.asset('assets/images/eliminar.png', height: 30),
              ],
            ),
          ),
          _AnimatedButton(
            onTap: onInicio,
            child: Column(
              children: [
                Image.asset('assets/images/hotel.png', height: 30),
                const SizedBox(height: 4),
                const Text(
                  'Inicio',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          _AnimatedButton(
            onTap: onGuardar,
            child: Row(
              children: [
                Image.asset('assets/images/guardar.png', height: 30),
                const SizedBox(width: 16),
                const Text(
                  'Guardar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedButton({required this.child, required this.onTap});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.9,
      upperBound: 1.0,
    );
    _scale = _controller.drive(Tween(begin: 1.0, end: 0.9));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animate() async {
    await _controller.reverse();
    await Future.delayed(const Duration(milliseconds: 50));
    await _controller.forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _animate,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54, width: 1),
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF098CD1), Color(0xFFE04747)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const AnimatedScaleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  void _triggerTap() async {
    setState(() => _isPressed = true);
    await _controller.forward();
    await Future.delayed(const Duration(milliseconds: 50));
    await _controller.reverse();
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _triggerLongPress() async {
    setState(() => _isPressed = true);
    await _controller.forward();
    await Future.delayed(const Duration(milliseconds: 50));
    await _controller.reverse();
    setState(() => _isPressed = false);
    widget.onLongPress?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerTap,
      onLongPress: widget.onLongPress != null ? _triggerLongPress : null,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isPressed ? 0.05 : 0.2),
                blurRadius: _isPressed ? 2 : 6,
                offset: _isPressed ? const Offset(1, 1) : const Offset(2, 4),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
