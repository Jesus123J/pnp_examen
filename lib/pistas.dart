// Motor de pistas y de analisis de errores.
//
// La idea central: las alternativas de este examen son deliberadamente
// casi identicas entre si. Fallar casi nunca es "no sabia", es "no vi la
// palabra que cambiaba". Estas funciones apuntan a esa palabra.

import 'modelo.dart';

const _vacias = {
  'DE', 'LA', 'EL', 'LOS', 'LAS', 'UN', 'UNA', 'UNOS', 'UNAS', 'Y', 'O', 'A',
  'EN', 'POR', 'PARA', 'CON', 'SIN', 'DEL', 'AL', 'SE', 'SU', 'SUS', 'ES',
  'SON', 'QUE', 'QUIEN', 'CUAL', 'CUALES', 'LO', 'ESTE', 'ESTA', 'ESTOS',
  'ESTAS', 'ESE', 'ESA', 'SEGUN', 'SOBRE', 'ANTE', 'DESDE', 'HASTA', 'ENTRE',
  'DURANTE', 'NO', 'SI', 'MAS', 'PERO', 'COMO', 'CUANDO', 'DONDE', 'TAMBIEN',
};

const _tildes = {
  'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ü': 'U',
  'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u',
};

String _sinTildes(String s) {
  var r = s;
  _tildes.forEach((k, v) => r = r.replaceAll(k, v));
  return r;
}

Set<String> _palabras(String s) => _sinTildes(s.toUpperCase())
    .split(RegExp(r'[^A-Z0-9ÑÜ]+'))
    .where((w) => w.length > 2 && !_vacias.contains(w))
    .toSet();

class Pista {
  final String titulo;
  final String texto;

  /// Indices de alternativas a ocultar (solo la pista 50/50).
  final List<int> descartar;

  const Pista(this.titulo, this.texto, {this.descartar = const []});
}

/// Genera las pistas en orden de menor a mayor ayuda.
List<Pista> generarPistas(Pregunta p) {
  final out = <Pista>[];

  // ---- Pista 1: donde esta la norma -------------------------------------
  final art = p.articulo;
  final partes = RegExp(r'\[([^\]]+)\]')
      .allMatches(p.ubicacion)
      .map((m) => m.group(1)!.trim())
      .toList();
  final ctx = partes.isEmpty ? '' : '\n${partes.join(' · ')}';
  out.add(Pista(
    'Dónde está la respuesta',
    art != null
        ? 'Esta pregunta sale del $art de:\n${p.materiaCorta}$ctx'
        : 'Materia: ${p.materiaCorta}$ctx',
  ));

  // ---- Pista 2: descartar dos alternativas incorrectas -------------------
  if (p.correcta >= 0 && p.alternativas.length > 3) {
    final malas = <int>[];
    for (var i = 0; i < p.alternativas.length; i++) {
      if (i != p.correcta) malas.add(i);
    }
    // descarta las dos menos parecidas a la correcta: son las mas faciles
    // de eliminar, asi la pista deja en pie la duda que de verdad importa
    final correcta = _palabras(p.alternativas[p.correcta]);
    malas.sort((a, b) {
      final sa = _palabras(p.alternativas[a]).intersection(correcta).length;
      final sb = _palabras(p.alternativas[b]).intersection(correcta).length;
      return sa.compareTo(sb);
    });
    out.add(Pista(
      'Descarte 50/50',
      'Se eliminaron dos alternativas incorrectas. '
          'Las que quedan son las que se parecen entre sí: '
          'ahí está la trampa.',
      descartar: malas.take(2).toList(),
    ));
  }

  // ---- Pista 3: palabras puente entre enunciado y respuesta --------------
  if (p.correcta >= 0) {
    final puente = _palabras(p.enunciado)
        .intersection(_palabras(p.alternativas[p.correcta]))
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    out.add(Pista(
      'Palabras clave',
      puente.isEmpty
          ? 'La respuesta correcta no repite palabras del enunciado: '
              'busca la que diga lo mismo con otros términos.'
          : 'El enunciado y la respuesta correcta comparten:\n'
              '${puente.take(5).join(' · ')}',
    ));
  }

  return out;
}

/// Analisis de por que fallaste, comparando tu opcion con la correcta.
class Analisis {
  final String diagnostico;
  final List<String> claveCorrecta; // palabras que solo trae la correcta
  final List<String> claveElegida; // palabras que solo traia la tuya
  final bool confusionCercana;

  Analisis({
    required this.diagnostico,
    required this.claveCorrecta,
    required this.claveElegida,
    required this.confusionCercana,
  });
}

Analisis analizarFallo(Pregunta p, int elegida) {
  if (p.correcta < 0 || elegida < 0) {
    return Analisis(
      diagnostico: 'Revisa la alternativa correcta.',
      claveCorrecta: const [],
      claveElegida: const [],
      confusionCercana: false,
    );
  }

  final c = _palabras(p.alternativas[p.correcta]);
  final e = _palabras(p.alternativas[elegida]);
  final comunes = c.intersection(e).length;
  final union = c.union(e).length;
  final similitud = union == 0 ? 0.0 : comunes / union;

  final soloC = c.difference(e).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  final soloE = e.difference(c).toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  String diag;
  if (similitud >= 0.55) {
    diag = 'Confusión por detalle. Las dos alternativas dicen casi lo mismo; '
        'la diferencia está en unas pocas palabras. Memoriza esa diferencia, '
        'no la frase completa.';
  } else if (similitud >= 0.25) {
    diag = 'Confusión parcial. Ibas por el concepto correcto pero elegiste una '
        'variante con un término cambiado. Fíjate en las palabras marcadas.';
  } else {
    diag = 'Contenido distinto. Tu opción habla de otra cosa: conviene volver '
        'a la norma antes de seguir practicando esta materia.';
  }

  return Analisis(
    diagnostico: diag,
    claveCorrecta: soloC.take(6).toList(),
    claveElegida: soloE.take(6).toList(),
    confusionCercana: similitud >= 0.55,
  );
}
