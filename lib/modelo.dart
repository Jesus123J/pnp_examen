// Modelos de datos del banco de preguntas.

const letras = 'ABCDE';

class Pregunta {
  final int id; // indice global, estable porque el asset no cambia
  final int n;
  final String materia;
  final String enunciado;
  final List<String> alternativas;
  final String respuesta;
  final String ubicacion;
  final String codigo;
  final int correcta; // indice 0..4, -1 si no se pudo determinar

  Pregunta({
    required this.id,
    required this.n,
    required this.materia,
    required this.enunciado,
    required this.alternativas,
    required this.respuesta,
    required this.ubicacion,
    required this.codigo,
    required this.correcta,
  });

  factory Pregunta.fromJson(int id, Map<String, dynamic> j) {
    final letra = j['letra_correcta'] as String?;
    return Pregunta(
      id: id,
      n: j['n'] as int,
      materia: (j['materia'] ?? '') as String,
      enunciado: (j['pregunta'] ?? '') as String,
      alternativas: List<String>.from(j['alternativas'] ?? const []),
      respuesta: (j['respuesta'] ?? '') as String,
      ubicacion: (j['ubicacion'] ?? '') as String,
      codigo: (j['codigo'] ?? '') as String,
      correcta: letra == null ? -1 : letras.indexOf(letra),
    );
  }

  /// Nombre corto de la materia para chips y titulos.
  String get materiaCorta {
    var m = materia;
    final corte = RegExp(r'\s+[-–]\s+|\s+\(');
    final i = m.indexOf(corte);
    if (i > 12) m = m.substring(0, i);
    return m.length > 46 ? '${m.substring(0, 44)}…' : m;
  }

  /// Articulo normativo extraido de la ubicacion, ej. "ART: 378" -> "Art. 378".
  String? get articulo {
    final m = RegExp(r'ART[:\s]*([\dA-Z°\-]+)').firstMatch(ubicacion);
    return m == null ? null : 'Art. ${m.group(1)}';
  }
}

/// Progreso de estudio de una pregunta, con repeticion espaciada.
class Progreso {
  int aciertos;
  int fallos;
  int nivel; // 0..6, sube al acertar y se reinicia al fallar
  int proximaRevision; // epoch ms
  bool marcada;

  Progreso({
    this.aciertos = 0,
    this.fallos = 0,
    this.nivel = 0,
    this.proximaRevision = 0,
    this.marcada = false,
  });

  /// Intervalos en dias por nivel: hoy, 1, 2, 4, 8, 16, 32.
  static const intervalos = [0, 1, 2, 4, 8, 16, 32];

  bool get vista => aciertos + fallos > 0;
  bool get pendiente =>
      DateTime.now().millisecondsSinceEpoch >= proximaRevision;

  void registrar(bool acierto) {
    final ahora = DateTime.now();
    if (acierto) {
      aciertos++;
      nivel = (nivel + 1).clamp(0, intervalos.length - 1);
    } else {
      fallos++;
      nivel = 0;
    }
    proximaRevision =
        ahora.add(Duration(days: intervalos[nivel])).millisecondsSinceEpoch;
  }

  Map<String, dynamic> toJson() => {
        'a': aciertos,
        'f': fallos,
        'n': nivel,
        'p': proximaRevision,
        'm': marcada,
      };

  factory Progreso.fromJson(Map<String, dynamic> j) => Progreso(
        aciertos: j['a'] ?? 0,
        fallos: j['f'] ?? 0,
        nivel: j['n'] ?? 0,
        proximaRevision: j['p'] ?? 0,
        marcada: j['m'] ?? false,
      );
}

/// Resultado de una sesion terminada.
class Resultado {
  final int total;
  final int aciertos;
  final int pistasUsadas;
  final Duration tiempo;
  final List<Pregunta> falladas;

  Resultado({
    required this.total,
    required this.aciertos,
    required this.pistasUsadas,
    required this.tiempo,
    required this.falladas,
  });

  double get porcentaje => total == 0 ? 0 : aciertos * 100 / total;
  bool get aprobado => porcentaje >= 60;
}

enum Modo { practica, repaso, simulacro, debiles, marcadas }
