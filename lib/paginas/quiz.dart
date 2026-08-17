import 'dart:async';

import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelo.dart';
import '../pistas.dart';
import 'resultado.dart';

class Quiz extends StatefulWidget {
  const Quiz({super.key, required this.preguntas, required this.modo});
  final List<Pregunta> preguntas;
  final Modo modo;

  @override
  State<Quiz> createState() => _QuizState();
}

class _QuizState extends State<Quiz> {
  int idx = 0;
  int? elegida;
  bool revelado = false;

  List<Pista> pistas = [];
  int pistasVistas = 0;
  final Set<int> ocultas = {};

  int aciertos = 0;
  int pistasTotales = 0;
  final List<Pregunta> falladas = [];

  final _inicio = DateTime.now();
  Timer? _timer;
  Duration _restante = const Duration(hours: 2);

  bool get esSimulacro => widget.modo == Modo.simulacro;
  Pregunta get p => widget.preguntas[idx];

  @override
  void initState() {
    super.initState();
    _prepararPregunta();
    if (esSimulacro) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _restante -= const Duration(seconds: 1));
        if (_restante.isNegative) _terminar();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _prepararPregunta() {
    pistas = generarPistas(p);
    pistasVistas = 0;
    ocultas.clear();
    elegida = null;
    revelado = false;
  }

  void _pedirPista() {
    if (pistasVistas >= pistas.length) return;
    setState(() {
      final pista = pistas[pistasVistas];
      ocultas.addAll(pista.descartar);
      pistasVistas++;
      pistasTotales++;
    });
  }

  void _responder(int i) {
    if (revelado) return;
    final ok = i == p.correcta;
    setState(() {
      elegida = i;
      revelado = true;
      if (ok) aciertos++;
      if (!ok) falladas.add(p);
    });
    AppEstado.i.registrar(p, ok);
  }

  void _siguiente() {
    if (idx + 1 >= widget.preguntas.length) {
      _terminar();
      return;
    }
    setState(() {
      idx++;
      _prepararPregunta();
    });
  }

  void _terminar() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaResultado(
          resultado: Resultado(
            total: idx + (revelado ? 1 : 0),
            aciertos: aciertos,
            pistasUsadas: pistasTotales,
            tiempo: DateTime.now().difference(_inicio),
            falladas: falladas,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marcada = AppEstado.i.prog(p.id).marcada;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmarSalida();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmarSalida,
          ),
          title: Text('${idx + 1} de ${widget.preguntas.length}'),
          actions: [
            if (esSimulacro)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    _fmt(_restante),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [],
                      color: _restante.inMinutes < 10 ? Colors.red : null,
                    ),
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Marcar para repasar',
              icon: Icon(marcada ? Icons.bookmark : Icons.bookmark_border),
              onPressed: () => setState(() => AppEstado.i.alternarMarca(p)),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (idx + 1) / widget.preguntas.length,
              minHeight: 4,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            Text(p.materiaCorta,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: 10),
            Text(p.enunciado,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(height: 1.4)),
            const SizedBox(height: 20),

            // --- pistas mostradas -----------------------------------------
            for (var i = 0; i < pistasVistas; i++) _TarjetaPista(pistas[i]),

            // --- alternativas ---------------------------------------------
            for (var i = 0; i < p.alternativas.length; i++)
              if (!ocultas.contains(i) || revelado)
                _Alternativa(
                  letra: letras[i],
                  texto: p.alternativas[i],
                  estado: _estadoDe(i),
                  atenuada: ocultas.contains(i) && !revelado,
                  onTap: () => _responder(i),
                ),

            if (revelado) ...[
              const SizedBox(height: 20),
              _Explicacion(
                pregunta: p,
                elegida: elegida!,
                onVerRelacionadas: _verRelacionadas,
              ),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: revelado
                ? FilledButton.icon(
                    onPressed: _siguiente,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(idx + 1 >= widget.preguntas.length
                        ? 'Ver resultado'
                        : 'Siguiente'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                  )
                : esSimulacro
                    ? const SizedBox(
                        height: 52,
                        child: Center(
                            child: Text('Simulacro: sin pistas. Elige una '
                                'alternativa.')),
                      )
                    : OutlinedButton.icon(
                        onPressed:
                            pistasVistas >= pistas.length ? null : _pedirPista,
                        icon: const Icon(Icons.lightbulb_outline),
                        label: Text(pistasVistas >= pistas.length
                            ? 'No quedan más pistas'
                            : 'Pedir pista '
                                '(${pistasVistas + 1} de ${pistas.length})'),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52)),
                      ),
          ),
        ),
      ),
    );
  }

  _EstadoAlt _estadoDe(int i) {
    if (!revelado) return _EstadoAlt.normal;
    if (i == p.correcta) return _EstadoAlt.correcta;
    if (i == elegida) return _EstadoAlt.incorrecta;
    return _EstadoAlt.normal;
  }

  void _verRelacionadas() {
    final otras = AppEstado.i.mismoArticulo(p);
    if (otras.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Quiz(preguntas: otras, modo: Modo.practica),
      ),
    );
  }

  Future<void> _confirmarSalida() async {
    if (idx == 0 && !revelado) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final salir = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Terminar la sesión?'),
        content: const Text('Tu progreso en cada pregunta ya quedó guardado.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Seguir')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Terminar')),
        ],
      ),
    );
    if (salir == true && mounted) _terminar();
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ---------------------------------------------------------------- widgets

enum _EstadoAlt { normal, correcta, incorrecta }

class _Alternativa extends StatelessWidget {
  const _Alternativa({
    required this.letra,
    required this.texto,
    required this.estado,
    required this.atenuada,
    required this.onTap,
  });

  final String letra, texto;
  final _EstadoAlt estado;
  final bool atenuada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color? borde, fondo, texto0;
    IconData? icono;

    switch (estado) {
      case _EstadoAlt.correcta:
        borde = Colors.green.shade600;
        fondo = Colors.green.withValues(alpha: .12);
        texto0 = Colors.green.shade900;
        icono = Icons.check_circle;
      case _EstadoAlt.incorrecta:
        borde = Colors.red.shade600;
        fondo = Colors.red.withValues(alpha: .12);
        texto0 = Colors.red.shade900;
        icono = Icons.cancel;
      case _EstadoAlt.normal:
        borde = cs.outlineVariant;
    }

    return Opacity(
      opacity: atenuada ? 0.25 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: fondo ?? cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: atenuada ? null : onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: borde, width: 1.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: borde.withValues(alpha: .2),
                    child: Text(letra,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: texto0 ?? cs.onSurface)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(texto,
                        style: TextStyle(height: 1.35, color: texto0)),
                  ),
                  if (icono != null) Icon(icono, color: borde, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaPista extends StatelessWidget {
  const _TarjetaPista(this.pista);
  final Pista pista;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.amber.withValues(alpha: .14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb, color: Colors.amber.shade800, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pista.titulo,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(pista.texto, style: const TextStyle(height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _Explicacion extends StatelessWidget {
  const _Explicacion({
    required this.pregunta,
    required this.elegida,
    required this.onVerRelacionadas,
  });

  final Pregunta pregunta;
  final int elegida;
  final VoidCallback onVerRelacionadas;

  @override
  Widget build(BuildContext context) {
    final acerto = elegida == pregunta.correcta;
    final relacionadas = AppEstado.i.mismoArticulo(pregunta);
    final a = acerto ? null : analizarFallo(pregunta, elegida);

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(acerto ? Icons.verified : Icons.school,
                    color: acerto ? Colors.green.shade700 : Colors.red.shade700),
                const SizedBox(width: 8),
                Text(acerto ? 'Correcto' : 'Qué pasó aquí',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),

            if (a != null) ...[
              Text(a.diagnostico, style: const TextStyle(height: 1.4)),
              const SizedBox(height: 14),
              if (a.claveCorrecta.isNotEmpty) ...[
                const Text('La correcta dice, y la tuya no:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final w in a.claveCorrecta)
                      Chip(
                        label: Text(w, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.green.withValues(alpha: .18),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (a.claveElegida.isNotEmpty) ...[
                const Text('Lo que decía la que elegiste:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final w in a.claveElegida)
                      Chip(
                        label: Text(w, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.red.withValues(alpha: .16),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],

            const Divider(),
            const SizedBox(height: 8),
            _Fila(
                icono: Icons.gavel,
                texto: pregunta.ubicacion.isEmpty
                    ? 'Sin referencia normativa'
                    : pregunta.ubicacion),
            _Fila(icono: Icons.folder_outlined, texto: pregunta.materia),
            if (pregunta.codigo.isNotEmpty)
              _Fila(
                  icono: Icons.tag,
                  texto: 'Código oficial ${pregunta.codigo}'),

            if (relacionadas.isNotEmpty) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: onVerRelacionadas,
                icon: const Icon(Icons.library_books_outlined),
                label: Text(
                    'Practicar las otras ${relacionadas.length} preguntas '
                    'de este artículo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.icono, required this.texto});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 16, color: Theme.of(context).hintColor),
            const SizedBox(width: 8),
            Expanded(
                child: Text(texto,
                    style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      );
}
