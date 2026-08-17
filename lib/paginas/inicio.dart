import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelo.dart';
import 'estadisticas.dart';
import 'materias.dart';
import 'quiz.dart';

class Inicio extends StatelessWidget {
  const Inicio({super.key});

  void _lanzar(BuildContext c, Modo modo, {String? materia, int n = 20}) {
    final ps = AppEstado.i.sesion(modo, materia: materia, cantidad: n);
    if (ps.isEmpty) {
      ScaffoldMessenger.of(c).showSnackBar(const SnackBar(
        content: Text('No hay preguntas disponibles para este modo todavía.'),
      ));
      return;
    }
    Navigator.push(
      c,
      MaterialPageRoute(builder: (_) => Quiz(preguntas: ps, modo: modo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = AppEstado.i;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: ListenableBuilder(
        listenable: e,
        builder: (context, _) => CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text('Examen de Ascenso PNP 2026'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.bar_chart),
                  tooltip: 'Estadísticas',
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const Estadisticas())),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList.list(children: [
                _Panel(e: e),
                const SizedBox(height: 24),
                Text('Modos de entrenamiento',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _Modo(
                  icono: Icons.play_arrow_rounded,
                  color: cs.primary,
                  titulo: 'Practicar',
                  sub: 'Empieza por lo que no has visto. 20 preguntas.',
                  onTap: () => _lanzar(context, Modo.practica),
                ),
                _Modo(
                  icono: Icons.refresh_rounded,
                  color: Colors.orange.shade700,
                  titulo: 'Repaso inteligente',
                  sub: e.pendientesHoy == 0
                      ? 'Nada pendiente. Vuelve mañana.'
                      : '${e.pendientesHoy} preguntas tocan hoy '
                          '(repetición espaciada)',
                  onTap: () => _lanzar(context, Modo.repaso),
                ),
                _Modo(
                  icono: Icons.warning_amber_rounded,
                  color: Colors.red.shade600,
                  titulo: 'Atacar mis puntos débiles',
                  sub: 'Preguntas de las materias donde peor vas.',
                  onTap: () => _lanzar(context, Modo.debiles),
                ),
                _Modo(
                  icono: Icons.timer_outlined,
                  color: Colors.purple.shade600,
                  titulo: 'Simulacro cronometrado',
                  sub: '100 preguntas · 2 horas · sin pistas',
                  onTap: () => _lanzar(context, Modo.simulacro, n: 100),
                ),
                _Modo(
                  icono: Icons.bookmark_rounded,
                  color: Colors.teal.shade600,
                  titulo: 'Marcadas para repasar',
                  sub: '${e.marcadas} preguntas guardadas',
                  onTap: () => _lanzar(context, Modo.marcadas, n: 50),
                ),
                _Modo(
                  icono: Icons.menu_book_rounded,
                  color: cs.secondary,
                  titulo: 'Estudiar por materia',
                  sub: '${e.porMateria.length} materias del temario',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const Materias())),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.e});
  final AppEstado e;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avance = e.vistas / e.preguntas.length;

    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tu avance',
                    style: Theme.of(context).textTheme.titleMedium),
                Text('${e.vistas} / ${e.preguntas.length}',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: avance,
                minHeight: 10,
                backgroundColor: cs.onPrimaryContainer.withValues(alpha: .15),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _Dato(
                    valor: '${e.precision.toStringAsFixed(0)}%',
                    etiqueta: 'Precisión'),
                _Dato(valor: '${e.dominadas}', etiqueta: 'Dominadas'),
                _Dato(valor: '${e.totalFallos}', etiqueta: 'Fallos'),
                _Dato(valor: '${e.pendientesHoy}', etiqueta: 'Hoy'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.valor, required this.etiqueta});
  final String valor, etiqueta;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(valor, style: Theme.of(context).textTheme.headlineSmall),
            Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}

class _Modo extends StatelessWidget {
  const _Modo({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.sub,
    required this.onTap,
  });

  final IconData icono;
  final Color color;
  final String titulo, sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: .15),
            child: Icon(icono, color: color),
          ),
          title: Text(titulo,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(sub),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
