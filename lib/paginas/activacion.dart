import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../acceso.dart';

class Activacion extends StatefulWidget {
  const Activacion({super.key, required this.onActivado});
  final VoidCallback onActivado;

  @override
  State<Activacion> createState() => _ActivacionState();
}

class _ActivacionState extends State<Activacion> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _verificando = false;
  int _intentos = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _activar() async {
    final codigo = _ctrl.text.trim();
    if (codigo.isEmpty) {
      setState(() => _error = 'Escribe tu código de acceso.');
      return;
    }

    setState(() {
      _verificando = true;
      _error = null;
    });

    // pequeña espera: desalienta probar códigos a fuerza bruta
    await Future.delayed(Duration(milliseconds: 400 + _intentos * 600));
    final ok = await Acceso.activar(codigo);
    if (!mounted) return;

    if (ok) {
      widget.onActivado();
    } else {
      setState(() {
        _verificando = false;
        _intentos++;
        _error = 'Ese código no es válido. Revisa que esté completo '
            '(formato PNP-XXXX-XXXX).';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.shield_outlined, size: 64, color: cs.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Examen de Ascenso PNP 2026',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '1500 preguntas del banco oficial',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Ingresa tu código de acceso',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ctrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.bold,
                    ),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(14),
                      TextInputFormatter.withFunction((ant, nuevo) {
                        return nuevo.copyWith(
                            text: nuevo.text.toUpperCase());
                      }),
                    ],
                    decoration: InputDecoration(
                      hintText: 'PNP-XXXX-XXXX',
                      border: const OutlineInputBorder(),
                      errorText: _error,
                      errorMaxLines: 3,
                    ),
                    onSubmitted: (_) => _activar(),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _verificando ? null : _activar,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    child: _verificando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text('Activar'),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    color: cs.surfaceContainerHighest,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'El código se pide una sola vez. Después la app '
                              'queda activada en este teléfono, y funciona '
                              'sin internet.',
                              style: TextStyle(fontSize: 13, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
