import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/ritmo.dart';
import '../sincronizacion.dart';

/// Franja que aparece arriba cuando no hay red o quedan cosas por subir.
///
/// Solo se muestra si hay algo que decir: una barra permanente de "todo bien"
/// se vuelve invisible a los dos días y deja de comunicar cuando importa.
class AvisoSinConexion extends ConsumerWidget {
  const AvisoSinConexion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(estadoOfflineProvider);
    if (!estado.hayAlgoQueAvisar) return const SizedBox.shrink();

    final esquema = Theme.of(context).colorScheme;
    final sinRed = !estado.hayConexion;

    final color = sinRed
        ? esquema.onErrorContainer
        : esquema.onTertiaryContainer;
    final fondo = sinRed ? esquema.errorContainer : esquema.tertiaryContainer;
    final icono = estado.esGrave
        ? Icons.warning_amber_rounded
        : (sinRed ? Icons.cloud_off : Icons.cloud_upload_outlined);

    final texto = estado.aviso;

    return Material(
      color: fondo,
      child: InkWell(
        // Sin red no tiene sentido reintentar; con red, tocar fuerza el envío.
        onTap: sinRed
            ? null
            : () => ref.read(sincronizadorProvider.notifier).sincronizar(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icono, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  texto,
                  style: TextStyle(color: color, fontSize: 13),
                ),
              ),
              if (estado.sincronizando)
                SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else if (!sinRed)
                Text(
                  'Subir ahora',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    )
        // Baja desde arriba en vez de aparecer de golpe. La franja empuja el
        // resto de la pantalla hacia abajo, y ese salto sin aviso hace que el
        // dedo toque otra cosa de la que apuntaba.
        .animate()
        .fadeIn(duration: Ritmo.normal(context))
        .slideY(begin: -1, end: 0, curve: Curves.easeOut);
  }
}
