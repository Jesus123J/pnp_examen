import 'package:flutter_test/flutter_test.dart';
import 'package:pnp_examen/modelo.dart';
import 'package:pnp_examen/pistas.dart';

Pregunta _p({
  required List<String> alts,
  int correcta = 0,
  String enunciado = 'CUAL ES EL PLAZO MAXIMO DE DETENCION PRELIMINAR:',
  String ubicacion = '(ART: 264) [LIBRO SEGUNDO] [TITULO II]',
}) =>
    Pregunta(
      id: 1,
      n: 1,
      materia: 'CODIGO PROCESAL PENAL - DECRETO LEGISLATIVO 957',
      enunciado: enunciado,
      alternativas: alts,
      respuesta: alts[correcta],
      ubicacion: ubicacion,
      codigo: '180838',
      correcta: correcta,
    );

void main() {
  group('generarPistas', () {
    test('la primera pista apunta al artículo de la norma', () {
      final p = _p(alts: ['A', 'B', 'C', 'D', 'E']);
      final pistas = generarPistas(p);
      expect(pistas.first.texto, contains('Art. 264'));
    });

    test('la pista 50/50 descarta exactamente dos alternativas', () {
      final p = _p(alts: ['A', 'B', 'C', 'D', 'E']);
      final medio = generarPistas(p).firstWhere((x) => x.descartar.isNotEmpty);
      expect(medio.descartar.length, 2);
    });

    test('el 50/50 nunca descarta la alternativa correcta', () {
      final p = _p(alts: ['A', 'B', 'C', 'D', 'E'], correcta: 3);
      for (final pista in generarPistas(p)) {
        expect(pista.descartar.contains(3), isFalse);
      }
    });

    test('deja en pie las alternativas más parecidas a la correcta', () {
      final p = _p(
        correcta: 0,
        alts: [
          'PLAZO MAXIMO DE VEINTICUATRO HORAS SALVO FLAGRANCIA',
          'PLAZO MAXIMO DE VEINTICUATRO HORAS SALVO MANDATO JUDICIAL',
          'TOTALMENTE DISTINTO SIN RELACION ALGUNA',
          'OTRA COSA COMPLETAMENTE AJENA AL TEMA',
          'PLAZO MAXIMO DE CUARENTA Y OCHO HORAS SALVO FLAGRANCIA',
        ],
      );
      final medio = generarPistas(p).firstWhere((x) => x.descartar.isNotEmpty);
      // las dos ajenas (indices 2 y 3) son las que deben caer
      expect(medio.descartar.toSet(), {2, 3});
    });
  });

  group('analizarFallo', () {
    test('detecta confusión por detalle entre opciones casi idénticas', () {
      final p = _p(
        correcta: 0,
        alts: [
          'RAZONES DE SANIDAD O POR MANDATO JUDICIAL O POR APLICACION DE LA LEY DE EXTRANJERIA',
          'RAZONES DE SANIDAD O POR MANDATO JUDICIAL O POR APLICACION DE LA LEY DE MIGRACIONES',
          'C',
          'D',
          'E',
        ],
      );
      final a = analizarFallo(p, 1);
      expect(a.confusionCercana, isTrue);
      expect(a.claveCorrecta, contains('EXTRANJERIA'));
      expect(a.claveElegida, contains('MIGRACIONES'));
    });

    test('detecta contenido totalmente distinto', () {
      final p = _p(
        correcta: 0,
        alts: [
          'VEINTICUATRO HORAS DESDE LA INTERVENCION POLICIAL',
          'EL MINISTERIO PUBLICO DIRIGE LA INVESTIGACION PREPARATORIA',
          'C',
          'D',
          'E',
        ],
      );
      expect(analizarFallo(p, 1).confusionCercana, isFalse);
    });
  });

  group('Progreso', () {
    test('al fallar reinicia el nivel y programa revisión inmediata', () {
      final g = Progreso(nivel: 4);
      g.registrar(false);
      expect(g.nivel, 0);
      expect(g.pendiente, isTrue);
    });

    test('al acertar sube de nivel y aleja la próxima revisión', () {
      final g = Progreso();
      g.registrar(true);
      expect(g.nivel, 1);
      expect(g.pendiente, isFalse);
    });

    test('el nivel no se desborda del máximo', () {
      final g = Progreso();
      for (var i = 0; i < 20; i++) {
        g.registrar(true);
      }
      expect(g.nivel, Progreso.intervalos.length - 1);
    });
  });
}
