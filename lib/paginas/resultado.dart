import 'package:flutter/material.dart';

import '../modelo.dart';
import 'quiz.dart';

class PantallaResultado extends StatelessWidget {
  const PantallaResultado({super.key, required this.resultado});
  final Resultado resultado;

  @override
  Widget build(BuildContext context) {
    final r = resultado;
    final color = r.aprobado ? Colors.green.shade600 : Colors.red.shade600;

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            color: color.withValues(alpha: .12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Text('${r.porcentaje.toStringAsFixed(0)}%',
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(
                              color: color, fontWeight: FontWeight.bold)),
                  Text('${r.aciertos} de ${r.total} correctas',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    r.aprobado
                        ? 'Por encima del 60%. Buen ritmo.'
                        : 'Debajo del 60%. Repasa las falladas.',
                    style: TextStyle(color: color),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metrica(
                  icono: Icons.timer_outlined,
                  valor: _fmt(r.tiempo),
                  etiqueta: 'Tiempo'),
              _Metrica(
                  icono: Icons.lightbulb_outline,
                  valor: '${r.pistasUsadas}',
                  etiqueta: 'Pistas'),
              _Metrica(
                  icono: Icons.speed,
                  valor: r.total == 0
                      ? '—'
                      : '${(r.tiempo.inSeconds / r.total).toStringAsFixed(0)}s',
                  etiqueta: 'Por pregunta'),
            ],
          ),
          const SizedBox(height: 24),
          if (r.falladas.isNotEmpty) ...[
            Text('Falladas (${r.falladas.length})',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Ya quedaron programadas para volver a salirte pronto en '
              'Repaso inteligente.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final p in r.falladas)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(p.enunciado,
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${letras[p.correcta >= 0 ? p.correcta : 0]}) '
                      '${p.respuesta}',
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.replay),
              label: const Text('Repetir solo las falladas'),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      Quiz(preguntas: r.falladas, modo: Modo.practica),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Volver al inicio'),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

class _Metrica extends StatelessWidget {
  const _Metrica(
      {required this.icono, required this.valor, required this.etiqueta});
  final IconData icono;
  final String valor, etiqueta;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icono, color: Theme.of(context).hintColor),
                const SizedBox(height: 6),
                Text(valor,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(etiqueta,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
}
