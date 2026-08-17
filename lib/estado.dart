// Estado global: carga del banco, progreso persistente y armado de sesiones.

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'modelo.dart';

class AppEstado extends ChangeNotifier {
  static final AppEstado i = AppEstado._();
  AppEstado._();

  final List<Pregunta> preguntas = [];
  final Map<String, List<Pregunta>> porMateria = {};
  final Map<int, Progreso> progreso = {};
  bool cargando = true;

  SharedPreferences? _prefs;
  final _rnd = Random();

  // ------------------------------------------------------------ carga

  Future<void> cargar() async {
    final raw = await rootBundle.loadString('assets/preguntas.json');
    final lista = jsonDecode(raw) as List;
    preguntas
      ..clear()
      ..addAll(lista.asMap().entries.map(
            (e) => Pregunta.fromJson(e.key, e.value as Map<String, dynamic>),
          ));

    porMateria.clear();
    for (final p in preguntas) {
      porMateria.putIfAbsent(p.materia, () => []).add(p);
    }

    _prefs = await SharedPreferences.getInstance();
    final guardado = _prefs!.getString('progreso');
    if (guardado != null) {
      final m = jsonDecode(guardado) as Map<String, dynamic>;
      m.forEach((k, v) {
        progreso[int.parse(k)] = Progreso.fromJson(v as Map<String, dynamic>);
      });
    }

    cargando = false;
    notifyListeners();
  }

  Future<void> _guardar() async {
    if (_prefs == null) return;
    await _prefs!.setString(
      'progreso',
      jsonEncode(progreso.map((k, v) => MapEntry('$k', v.toJson()))),
    );
  }

  // --------------------------------------------------------- progreso

  Progreso prog(int id) => progreso.putIfAbsent(id, () => Progreso());

  void registrar(Pregunta p, bool acierto) {
    prog(p.id).registrar(acierto);
    _guardar();
    notifyListeners();
  }

  void alternarMarca(Pregunta p) {
    final g = prog(p.id);
    g.marcada = !g.marcada;
    _guardar();
    notifyListeners();
  }

  Future<void> reiniciar() async {
    progreso.clear();
    await _guardar();
    notifyListeners();
  }

  // ------------------------------------------------------ estadisticas

  int get vistas => progreso.values.where((g) => g.vista).length;
  int get totalAciertos =>
      progreso.values.fold(0, (s, g) => s + g.aciertos);
  int get totalFallos => progreso.values.fold(0, (s, g) => s + g.fallos);

  double get precision {
    final t = totalAciertos + totalFallos;
    return t == 0 ? 0 : totalAciertos * 100 / t;
  }

  int get pendientesHoy => preguntas
      .where((p) => progreso[p.id]?.vista == true && progreso[p.id]!.pendiente)
      .length;

  int get marcadas => progreso.values.where((g) => g.marcada).length;

  int get dominadas =>
      progreso.values.where((g) => g.nivel >= 4 && g.aciertos > g.fallos).length;

  /// Precision por materia, solo con las respondidas.
  ({int vistas, int total, double precision}) statsMateria(String m) {
    final ps = porMateria[m] ?? const <Pregunta>[];
    var ac = 0, fa = 0, vi = 0;
    for (final p in ps) {
      final g = progreso[p.id];
      if (g == null || !g.vista) continue;
      vi++;
      ac += g.aciertos;
      fa += g.fallos;
    }
    final t = ac + fa;
    return (vistas: vi, total: ps.length, precision: t == 0 ? 0 : ac * 100 / t);
  }

  // -------------------------------------------------- armado de sesiones

  List<Pregunta> sesion(Modo modo, {String? materia, int cantidad = 20}) {
    switch (modo) {
      case Modo.practica:
        final base = materia == null
            ? [...preguntas]
            : [...(porMateria[materia] ?? const <Pregunta>[])];
        // primero las nunca vistas, luego las de peor rendimiento
        base.sort((a, b) {
          final ga = progreso[a.id], gb = progreso[b.id];
          final va = ga?.vista == true ? 1 : 0;
          final vb = gb?.vista == true ? 1 : 0;
          if (va != vb) return va - vb;
          final na = ga?.nivel ?? 0, nb = gb?.nivel ?? 0;
          return na - nb;
        });
        return base.take(cantidad).toList();

      case Modo.repaso:
        final due = preguntas.where((p) {
          final g = progreso[p.id];
          return g != null && g.vista && g.pendiente;
        }).toList()
          ..sort((a, b) {
            final ga = progreso[a.id]!, gb = progreso[b.id]!;
            if (ga.nivel != gb.nivel) return ga.nivel - gb.nivel;
            return gb.fallos.compareTo(ga.fallos);
          });
        return due.take(cantidad).toList();

      case Modo.debiles:
        final ordenadas = porMateria.keys.toList()
          ..sort((a, b) {
            final sa = statsMateria(a), sb = statsMateria(b);
            if (sa.vistas == 0 && sb.vistas == 0) return 0;
            if (sa.vistas == 0) return 1;
            if (sb.vistas == 0) return -1;
            return sa.precision.compareTo(sb.precision);
          });
        final out = <Pregunta>[];
        for (final m in ordenadas) {
          if (statsMateria(m).vistas == 0) continue;
          final ps = [...porMateria[m]!]..sort((a, b) {
              final ga = progreso[a.id], gb = progreso[b.id];
              return (gb?.fallos ?? 0).compareTo(ga?.fallos ?? 0);
            });
          out.addAll(ps.take(6));
          if (out.length >= cantidad) break;
        }
        if (out.isEmpty) return sesion(Modo.practica, cantidad: cantidad);
        return out.take(cantidad).toList();

      case Modo.marcadas:
        return preguntas
            .where((p) => progreso[p.id]?.marcada == true)
            .take(cantidad)
            .toList();

      case Modo.simulacro:
        // muestra proporcional al peso real de cada materia en el banco
        final out = <Pregunta>[];
        porMateria.forEach((m, ps) {
          final cuota = (ps.length / preguntas.length * cantidad).round();
          final copia = [...ps]..shuffle(_rnd);
          out.addAll(copia.take(max(1, cuota)));
        });
        out.shuffle(_rnd);
        return out.take(cantidad).toList();
    }
  }

  /// Otras preguntas que citan el mismo articulo: sirve para estudiar el
  /// punto exacto que fallaste en vez de la materia entera.
  List<Pregunta> mismoArticulo(Pregunta p) {
    final art = p.articulo;
    if (art == null) return const [];
    return preguntas
        .where((o) =>
            o.id != p.id && o.materia == p.materia && o.articulo == art)
        .toList();
  }
}
