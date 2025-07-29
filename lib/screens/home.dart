import 'dart:ui';
import 'package:flutter/material.dart';
import 'oficina.dart';
import 'edificio.dart';
import 'asistencia_edificio.dart';
import 'reportes_generales.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo degradado fijo
          Container(
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
          ),

          // Contenido principal
          SafeArea(
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
                    height: 16,
                    color: const Color(0xFFD9D9D9),
                  ),
                  Center(
                    child: Image.asset(
                      'assets/images/Logo.png',
                      height: screenHeight * 0.1,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // Botones
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                    ),
                    child: Column(
                      children: [
                        AnimatedHomeButton(
                          iconPath: 'assets/images/oficina.png',
                          label: 'Oficina',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OficinaPage(),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        AnimatedHomeButton(
                          iconPath: 'assets/images/hotel.png',
                          label: 'Edificio',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EdificioPage(),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        AnimatedHomeButton(
                          iconPath: 'assets/images/verificar.png',
                          label: 'Asistencia Edificio',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const AsistenciaEdificioPage(),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        AnimatedHomeButton(
                          iconPath: 'assets/images/area.png',
                          label: 'Reportes Generales',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ReportesGeneralesPage(),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: screenHeight * 0.04),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedHomeButton extends StatefulWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const AnimatedHomeButton({
    super.key,
    required this.iconPath,
    required this.label,
    required this.onTap,
  });

  @override
  State<AnimatedHomeButton> createState() => _AnimatedHomeButtonState();
}

class _AnimatedHomeButtonState extends State<AnimatedHomeButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(_controller);
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
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF84BAE7), Color(0xFF008CFF)],
              stops: [0.25, 0.96],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color.fromARGB(255, 224, 165, 165),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(widget.iconPath, height: 50),
              const SizedBox(width: 20),
              Expanded(
                child: Center(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
