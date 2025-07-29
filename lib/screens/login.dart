import 'package:flutter/material.dart';
import 'dart:ui'; // Para el blur
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'home.dart';

String encriptar(String texto) {
  final bytes = utf8.encode(texto);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  Future<void> validarLogin() async {
    final usuario = _usuarioController.text.trim();
    final contrasena = encriptar(_contrasenaController.text.trim());

    if (usuario.isEmpty || contrasena.isEmpty) {
      _mostrarMensaje("Por favor, completa ambos campos.");
      return;
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .where('usuario', isEqualTo: usuario)
              .where('contrasena', isEqualTo: contrasena)
              .get();
      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
          );
        });
      } else {
        _mostrarMensaje("❌ Usuario o contraseña incorrectos.");
      }
    } catch (e) {
      _mostrarMensaje("Error al conectar con la base de datos.");
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF096ECD),
                Color.fromARGB(176, 2, 104, 194),
                Color.fromARGB(132, 2, 98, 177),
                Color.fromARGB(255, 224, 71, 71),
              ],
              stops: [0.0, 0.32, 0.54, 1.0],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.43,
                  child: Image.asset(
                    'assets/images/LogoEdi.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 10,
                  color: const Color(0xFFD9D9D9),
                ),
                Center(
                  child: Image.asset(
                    'assets/images/Logo.png',
                    height: screenHeight * 0.1,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Image.asset(
                              'assets/images/vidrio.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: screenHeight * 0.04,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/trabajador.png',
                                  height: screenHeight * 0.06,
                                ),
                                SizedBox(height: screenHeight * 0.025),
                                TextField(
                                  controller: _usuarioController,
                                  decoration: InputDecoration(
                                    hintText: 'Usuario',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFF26262),
                                        width: 2,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFF26262),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                TextField(
                                  controller: _contrasenaController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    hintText: 'Contraseña',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFF26262),
                                        width: 2,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFF26262),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                AnimatedLoginButton(onPressed: validarLogin),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🔘 Botón con animación visual al tocar
class AnimatedLoginButton extends StatefulWidget {
  final VoidCallback onPressed;

  const AnimatedLoginButton({super.key, required this.onPressed});

  @override
  State<AnimatedLoginButton> createState() => _AnimatedLoginButtonState();
}

class _AnimatedLoginButtonState extends State<AnimatedLoginButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerAnimation() async {
    await _controller.forward();
    await Future.delayed(const Duration(milliseconds: 50));
    await _controller.reverse();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: _triggerAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 218, 32, 32).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color.fromARGB(
                    255,
                    84,
                    128,
                    223,
                  ).withOpacity(0.3),
                ),
              ),
              child: Image.asset(
                'assets/images/entrar.png',
                height: screenHeight * 0.06,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
