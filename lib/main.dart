import 'package:flutter/material.dart';

import 'acceso.dart';
import 'estado.dart';
import 'paginas/activacion.dart';
import 'paginas/inicio.dart';

/// Códigos de acceso autorizados.
///
/// Van como hash SHA-256 con sal, NO en texto plano: así no aparecen al
/// abrir el APK con un editor ni con `strings`. Los códigos legibles están
/// solo en tu archivo CODIGOS_DE_ACCESO.txt, fuera del proyecto.
///
/// Para agregar más códigos:  dart run tool/generar_codigos.dart 5
const codigosAutorizados = <String>[
  '035111dbab2f653c73172218c76024f90094a8ebc571c507e47eadac10251789', // 01
  '4d3a9cd03dccbb3ffded2cf70d9ffa2e6a1131e1c94b1938bacf695a9f3b2baa', // 02
  '2388eee274445d80094e5e8e53657eb619102d4232dd9a002eeacc4b453cd92c', // 03
  'fb7b3e04271ce34fa3a8fb3b821e77f480237cef1faa4c1e7660b90ccd5ea195', // 04
  '10c1e55b8dfe432aad91e1d0bacea41bfa105416dfe9cbda9c2011c23589c228', // 05
  '8251223dd227b1a3d93f4c9712938b8d21b98907cc6e3748dfd95858591420c1', // 06
  '370e7971949799f5553a62c6fe175dd6785f77c63403ef07d9bd7e9d7f019131', // 07
  '944c067352ac66b814d5a1a3f8ae1f46b22e5514e1b1a1f8df8b1234c7d0950b', // 08
  '59f690ed7a28bff512d007b763c70dc8ea2065f76500306b3e04cebfcff7b527', // 09
  'bfdc3cb755bc54540af81c030d2e3b09da3361ae4677cab9e6668063f50b7548', // 10
];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Acceso.configurar(codigosAutorizados);
  runApp(const App());
}

const azul = Color(0xFF16447A);

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late Future<bool> _arranque = _iniciar();
  bool _activado = false;

  Future<bool> _iniciar() async {
    await AppEstado.i.cargar();
    _activado = await Acceso.estaActivado();
    return _activado;
  }

  void _desbloquear() {
    setState(() {
      _activado = true;
      _arranque = Future.value(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Examen PNP 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: azul),
        cardTheme: const CardThemeData(elevation: 0),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(seedColor: azul, brightness: Brightness.dark),
      ),
      home: FutureBuilder<bool>(
        future: _arranque,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Cargando 1500 preguntas…'),
                  ],
                ),
              ),
            );
          }
          if (snap.hasError) {
            return Scaffold(
              body: Center(child: Text('Error al cargar: ${snap.error}')),
            );
          }
          if (!_activado) {
            return Activacion(onActivado: _desbloquear);
          }
          return const Inicio();
        },
      ),
    );
  }
}
