// Control de acceso por codigo de activacion.
//
// LIMITACION REAL, para que quede escrito: esto valida contra una lista
// dentro del propio APK. Los codigos van hasheados con SHA-256 y sal, asi
// que no se leen con `strings` ni abriendo el APK con un editor. Pero quien
// sepa decompilar puede parchear la funcion `validar` y saltarse el candado
// por completo. La unica proteccion real es validar contra un servidor.
// Sirve para vender entre conocidos, no para frenar a alguien decidido.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Acceso {
  Acceso._();

  static const _sal = 'pnp2026-siecopol-v1';
  static const _clave = 'codigo_activado';

  static List<String> _autorizados = const [];

  /// Se llama una vez desde main() con la lista de hashes autorizados.
  static void configurar(List<String> hashes) => _autorizados = hashes;

  /// Deja el codigo como el usuario deberia escribirlo: PNP-XXXX-XXXX
  static String normalizar(String entrada) {
    final limpio =
        entrada.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (limpio.length == 11 && limpio.startsWith('PNP')) {
      return 'PNP-${limpio.substring(3, 7)}-${limpio.substring(7)}';
    }
    return limpio;
  }

  static String _hash(String codigo) =>
      sha256.convert(utf8.encode('$_sal$codigo')).toString();

  static bool validar(String entrada) =>
      _autorizados.contains(_hash(normalizar(entrada)));

  static Future<bool> estaActivado() async {
    final p = await SharedPreferences.getInstance();
    final guardado = p.getString(_clave);
    return guardado != null && _autorizados.contains(guardado);
  }

  /// Guarda la activacion si el codigo es valido. Devuelve si entro.
  static Future<bool> activar(String entrada) async {
    if (!validar(entrada)) return false;
    final p = await SharedPreferences.getInstance();
    await p.setString(_clave, _hash(normalizar(entrada)));
    await p.setInt(
        'activado_el', DateTime.now().millisecondsSinceEpoch);
    return true;
  }

  static Future<void> desactivar() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_clave);
  }
}
