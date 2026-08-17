# Examen PNP 2026 — entrenador

App Flutter para preparar el examen de ascenso de Suboficiales de Armas y
Servicios PNP 2026, sobre el banco oficial de **1500 preguntas**.

## Cómo correrla

```bash
cd ~/pnp_examen

flutter run -d chrome      # más rápido para probar, no necesita Xcode
flutter devices            # ver emuladores/celulares Android conectados
flutter run                # correr en el dispositivo detectado
```

Para generar el instalable de Android:

```bash
flutter build apk --release
# queda en build/app/outputs/flutter-apk/app-release.apk
```

> En iPhone no corre todavía: falta Xcode y una cuenta de Apple Developer de
> pago. En Android y en Chrome funciona completo.

## Qué hace distinto

### Pistas escalonadas antes de revelar

Tres niveles, de menor a mayor ayuda. Puedes parar en el que quieras:

1. **Dónde está la respuesta** — el artículo exacto de la norma
   (ej. "Art. 378 · Libro Tercero · Sección III"). Te dice dónde estudiar sin
   decirte qué responder.
2. **Descarte 50/50** — elimina dos alternativas incorrectas. No elimina dos
   al azar: elimina las **menos parecidas** a la correcta, así te deja
   enfrentado a las dos que de verdad se confunden entre sí.
3. **Palabras clave** — los términos que comparten el enunciado y la respuesta
   correcta.

### Análisis real al fallar

En este examen las alternativas son casi idénticas a propósito
("razones de sanidad" vs "causas de salubridad"). Fallar casi nunca es *no
sabía*, es *no vi la palabra que cambiaba*.

Al equivocarte la app compara tu opción con la correcta y te muestra:

- Un diagnóstico según qué tan parecidas eran: confusión por detalle,
  confusión parcial, o contenido totalmente distinto.
- **Las palabras exactas** que traía la correcta y no la tuya, y viceversa.
- La referencia normativa y el código oficial de la pregunta.
- Un botón para practicar **las otras preguntas del mismo artículo** — así
  atacas el punto exacto que fallaste, no la materia entera.

### Repetición espaciada

Cada pregunta lleva su propio nivel (0 a 6) con intervalos de
0, 1, 2, 4, 8, 16 y 32 días. Aciertas y se aleja; fallas y vuelve hoy mismo.
El modo **Repaso inteligente** te sirve las que tocan.

### Modos

| Modo | Para qué |
|---|---|
| Practicar | Prioriza lo que nunca has visto |
| Repaso inteligente | Lo que toca hoy según repetición espaciada |
| Puntos débiles | Preguntas de las materias con peor porcentaje |
| Simulacro | 100 preguntas · 2 horas · sin pistas · muestra proporcional por materia |
| Marcadas | Las que guardaste con el marcador |
| Por materia | Las 22 materias del temario |

## Estructura

```
lib/
├── modelo.dart          Pregunta, Progreso (repetición espaciada), Resultado
├── estado.dart          Carga del asset, persistencia, armado de sesiones
├── pistas.dart          Motor de pistas y análisis de errores  <- el núcleo
└── paginas/
    ├── inicio.dart      Panel de avance y modos
    ├── quiz.dart        Pregunta, pistas, revelado, explicación
    ├── resultado.dart   Cierre de sesión
    ├── materias.dart    Las 22 materias con su progreso
    └── estadisticas.dart  Materias ordenadas de peor a mejor
```

El progreso se guarda en `shared_preferences`, así que sobrevive al cerrar la
app. Se puede borrar desde Estadísticas → icono de reinicio.

## Tests

```bash
flutter test
```

Cubren el motor de pistas (que el 50/50 nunca descarte la correcta, que deje en
pie las alternativas parecidas) y la repetición espaciada.

## Sobre los datos

Extraídos del PDF oficial con `pdftotext` y limpiados de la marca de agua.
1500 preguntas, todas con sus 5 alternativas y su respuesta identificada;
1470 conservan el código oficial. La fuente está en
`assets/preguntas.json`.
