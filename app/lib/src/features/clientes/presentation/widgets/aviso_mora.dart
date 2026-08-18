import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ritmo.dart';
import '../../../../core/utils/guaranies.dart';
import '../../application/clientes_controller.dart';

/// HU-09 — aviso dentro de la app cuando hay clientes atrasados.
///
/// Aparece arriba del listado y lleva directo al filtro de atrasados. Solo se
/// muestra si hay alguno: un cartel permanente deja de leerse a los dos días.
class AvisoDeMora extends ConsumerWidget {
  const AvisoDeMora({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soloMora = ref.watch(filtroSoloMoraProvider);
    final lista = ref.watch(moraProvider).value;

    // Estando ya en la lista de atrasados el aviso sobra.
    if (soloMora || lista == null || lista.vacia) {
      return const SizedBox.shrink();
    }

    final tema = Theme.of(context);
    final cantidad = lista.datos.length;
    final plural = cantidad == 1 ? 'cliente lleva' : 'clientes llevan';

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: tema.colorScheme.errorContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            ref.read(filtroSoloMoraProvider.notifier).mostrarSoloMora(true),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: tema.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$cantidad $plural más de ${lista.diasMoraConfig} días sin pagar',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tema.colorScheme.onErrorContainer,
                      ),
                    ),
                    Text(
                      'Te deben ${formatearGuaranies(lista.deudaEnMora)}',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: tema.colorScheme.onErrorContainer,
              ),
            ],
          ),
        ),
      ),
    )
        // Entra creciendo apenas, no desde cero: es un aviso, no un anuncio.
        .animate()
        .fadeIn(duration: Ritmo.normal(context))
        .scaleXY(begin: .97, end: 1, curve: Curves.easeOut);
  }
}
