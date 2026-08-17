import 'package:flutter_test/flutter_test.dart';
import 'package:pnp_examen/acceso.dart';
import 'package:pnp_examen/main.dart' show codigosAutorizados;

void main() {
  setUp(() => Acceso.configurar(codigosAutorizados));

  group('normalizar', () {
    test('acepta el código sin guiones', () {
      expect(Acceso.normalizar('pnprcurcgm2'), 'PNP-RCUR-CGM2');
    });

    test('acepta minúsculas y espacios sueltos', () {
      expect(Acceso.normalizar(' pnp-rcur-cgm2 '), 'PNP-RCUR-CGM2');
    });
  });

  group('validar', () {
    test('acepta un código de la lista autorizada', () {
      expect(Acceso.validar('PNP-RCUR-CGM2'), isTrue);
    });

    test('lo acepta aunque venga mal formateado', () {
      expect(Acceso.validar('pnp rcur cgm2'), isTrue);
    });

    test('rechaza un código inventado', () {
      expect(Acceso.validar('PNP-XXXX-XXXX'), isFalse);
    });

    test('rechaza vacío y basura', () {
      expect(Acceso.validar(''), isFalse);
      expect(Acceso.validar('12345'), isFalse);
    });

    test('rechaza un código con un solo carácter cambiado', () {
      expect(Acceso.validar('PNP-RCUR-CGM3'), isFalse);
    });
  });

  test('hay exactamente 10 códigos autorizados y sin repetir', () {
    expect(codigosAutorizados.length, 10);
    expect(codigosAutorizados.toSet().length, 10);
  });

  test('los códigos no viajan en texto plano en el binario', () {
    // todos deben ser hashes hex de 64 caracteres
    for (final h in codigosAutorizados) {
      expect(h.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(h), isTrue);
      expect(h.toUpperCase().contains('PNP'), isFalse);
    }
  });
}
