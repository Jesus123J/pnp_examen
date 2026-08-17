import 'package:flutter/material.dart';

import '../estado.dart';
import '../modelo.dart';
import 'quiz.dart';

class Materias extends StatelessWidget {
  const Materias({super.key});

  @override
  Widget build(BuildContext context) {
    final e = AppEstado.i;
    final keys = e.porMateria.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Materias del temario')),
      body: ListenableBuilder(
        listenable: e,
        builder: (context, _) => ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: keys.length,
          itemBuilder: (context, i) {
            final m = keys[i];
            final s = e.statsMateria(m);
            final avance = s.total == 0 ? 0.0 : s.vistas / s.total;
            final color = s.vistas == 0
                ? Theme.of(context).hintColor
                : s.precision >= 70
                    ? Colors.green.shade600
                    : s.precision >= 50
                        ? Colors.orange.shade700
                        : Colors.red.shade600;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final ps =
                      e.sesion(Modo.practica, materia: m, cantidad: 20);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          Quiz(preguntas: ps, modo: Modo.practica),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(m,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, height: 1.3)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s.vistas == 0
                                  ? 'nuevo'
                                  : '${s.precision.toStringAsFixed(0)}%',
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                            value: avance, minHeight: 6),
                      ),
                      const SizedBox(height: 6),
                      Text('${s.vistas} de ${s.total} preguntas vistas',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
