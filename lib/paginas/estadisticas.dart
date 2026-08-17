import 'package:flutter/material.dart';

import '../estado.dart';

class Estadisticas extends StatelessWidget {
  const Estadisticas({super.key});

  @override
  Widget build(BuildContext context) {
    final e = AppEstado.i;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis estadísticas'),
        actions: [
          IconButton(
            tooltip: 'Reiniciar progreso',
            icon: const Icon(Icons.restart_alt),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('¿Borrar todo el progreso?'),
                  content: const Text(
                      'Se pierden aciertos, fallos, marcadas y la '
                      'programación de repasos. No se puede deshacer.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Borrar')),
                  ],
                ),
              );
              if (ok == true) await e.reiniciar();
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: e,
        builder: (context, _) {
          final materias = e.porMateria.keys.toList()
            ..sort((a, b) {
              final sa = e.statsMateria(a), sb = e.statsMateria(b);
              if (sa.vistas == 0 && sb.vistas == 0) return 0;
              if (sa.vistas == 0) return 1;
              if (sb.vistas == 0) return -1;
              return sa.precision.compareTo(sb.precision);
            });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Ficha(
                      valor: '${e.vistas}',
                      etiqueta: 'Preguntas trabajadas',
                      total: '${e.preguntas.length}'),
                  _Ficha(
                      valor: '${e.precision.toStringAsFixed(0)}%',
                      etiqueta: 'Precisión global'),
                  _Ficha(valor: '${e.dominadas}', etiqueta: 'Dominadas'),
                  _Ficha(
                      valor: '${e.pendientesHoy}',
                      etiqueta: 'Repasos para hoy'),
                ],
              ),
              const SizedBox(height: 28),
              Text('Materias, de peor a mejor',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Empieza por arriba: ahí está tu mayor ganancia.',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 14),
              for (final m in materias) _BarraMateria(materia: m),
            ],
          );
        },
      ),
    );
  }
}

class _Ficha extends StatelessWidget {
  const _Ficha({required this.valor, required this.etiqueta, this.total});
  final String valor, etiqueta;
  final String? total;

  @override
  Widget build(BuildContext context) {
    final ancho = (MediaQuery.of(context).size.width - 42) / 2;
    return SizedBox(
      width: ancho,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(valor,
                      style: Theme.of(context).textTheme.headlineMedium),
                  if (total != null)
                    Text(' / $total',
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 2),
              Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarraMateria extends StatelessWidget {
  const _BarraMateria({required this.materia});
  final String materia;

  @override
  Widget build(BuildContext context) {
    final s = AppEstado.i.statsMateria(materia);
    final color = s.vistas == 0
        ? Theme.of(context).hintColor
        : s.precision >= 70
            ? Colors.green.shade600
            : s.precision >= 50
                ? Colors.orange.shade700
                : Colors.red.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(materia,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.25)),
              ),
              const SizedBox(width: 8),
              Text(
                s.vistas == 0
                    ? 'sin datos'
                    : '${s.precision.toStringAsFixed(0)}%',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: s.vistas == 0 ? 0 : s.precision / 100,
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: .15),
            ),
          ),
        ],
      ),
    );
  }
}
