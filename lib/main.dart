import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi App con Firebase',
      home: Scaffold(
        appBar: AppBar(title: Text('Inicio')),
        body: Center(child: Text('Firebase conectado 🎉')),
      ),
    );
  }
}
