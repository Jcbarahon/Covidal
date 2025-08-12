import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

// Ajusta el import a tu ruta real del archivo login.dart
//import 'package:your_package/screens/login.dart';
import 'package:covidal/screens/login.dart';


void main() {
  group('encriptar()', () {
    test('devuelve SHA-256 (hex) correcto para un texto simple', () {
      const input = 'hola';
      final esperado = sha256.convert(utf8.encode(input)).toString();
      expect(encriptar(input), esperado);
    });

    test('es determinístico para el mismo input', () {
      expect(encriptar('abc123'), encriptar('abc123'));
    });

    test('maneja string vacío', () {
      final esperado = sha256.convert(utf8.encode('')).toString();
      expect(encriptar(''), esperado);
    });

    test('soporta unicode', () {
      const input = 'áéíóúÑ🙂';
      final esperado = sha256.convert(utf8.encode(input)).toString();
      expect(encriptar(input), esperado);
    });

    test('distingue mayúsculas/minúsculas (propiedad del hash)', () {
      expect(encriptar('Usuario'), isNot(encriptar('usuario')));
    });

    test('ignora espacios en los extremos si previamente se hace trim en login', () {
      // en tu login haces .trim() ANTES de encriptar; validamos consistencia
      const base = 'claveSecreta';
      expect(encriptar(' $base '), isNot(encriptar(base))); // encriptar() no trimea
      // La responsabilidad del trim está fuera de encriptar(), como en tu código
    });
  });
}
