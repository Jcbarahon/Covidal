import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/login.dart'; // importa la pantalla que creamos
import 'screens/home.dart'; // ← nueva pantalla principal
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  try {
    final snapshot = await FirebaseFirestore.instance.collection('test').get();
    print("Conexión exitosa. Documentos: ${snapshot.docs.length}");
  } catch (e) {
    print("Error al conectar con Firebase: $e");
  }
  await initializeDateFormatting('es', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Login(), //í pones la pantalla de login
      routes: {'/home': (context) => const Home()},
    );
  }
}
