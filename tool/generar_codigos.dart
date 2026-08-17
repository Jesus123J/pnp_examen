// ignore_for_file: avoid_print  (es una herramienta de consola)
//
// Genera nuevos codigos de acceso y sus hashes.
//
//   dart run tool/generar_codigos.dart 5
//
// Copia los HASHES a `codigosAutorizados` en lib/main.dart y guarda los
// codigos legibles en tu archivo privado. Nunca subas los codigos legibles
// al proyecto: el APK se puede abrir.

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

const sal = 'pnp2026-siecopol-v1';

// sin O ni I para que nadie los confunda con 0 y 1 al dictarlos
const alfabeto = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

void main(List<String> args) {
  final cuantos = args.isEmpty ? 10 : int.tryParse(args.first) ?? 10;
  final rnd = Random.secure();
  String bloque(int n) =>
      List.generate(n, (_) => alfabeto[rnd.nextInt(alfabeto.length)]).join();

  final codigos = <String>{};
  while (codigos.length < cuantos) {
    codigos.add('PNP-${bloque(4)}-${bloque(4)}');
  }

  print('=== CODIGOS (guardalos en privado, son los que vendes) ===');
  for (final c in codigos) {
    print(c);
  }

  print('\n=== HASHES (pegalos en codigosAutorizados de lib/main.dart) ===');
  var i = 0;
  for (final c in codigos) {
    final h = sha256.convert(utf8.encode('$sal$c')).toString();
    print("  '$h', // ${(++i).toString().padLeft(2, '0')}");
  }
}
