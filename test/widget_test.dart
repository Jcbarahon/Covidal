import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:covidal/main.dart';
import 'package:covidal/screens/login.dart';
import 'package:covidal/screens/home.dart';

void main() {
  testWidgets('La app carga y muestra Login como pantalla inicial', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Login), findsOneWidget);
  });

  testWidgets('La ruta /home navega y muestra Home', (tester) async {
    await tester.pumpWidget(const MyApp());

    // Usa el Navigator existente en el árbol
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/home');
    await tester.pumpAndSettle();

    expect(find.byType(Home), findsOneWidget);
  });
}
