import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  const texto = 'covidal';
  final bytes = utf8.encode(texto);
  final hash = sha256.convert(bytes);
  print('Hash SHA-256: $hash');
}
