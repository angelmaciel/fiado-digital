import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/guaranies.dart';
import '../../../perfil/application/perfil_controller.dart';
import '../../application/clientes_controller.dart';
import '../../domain/cliente_en_mora.dart';
import 'boton_whatsapp.dart';

/// HU-06 — quiénes deben y hace tiempo que no pagan, del más atrasado al menos.
class ListaMoraView extends ConsumerWidget {
  const ListaMoraView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mora = ref.watch(moraProvider);

    return mora.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            error is ApiException ? error.mensaje : error.toString(),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (lista) {
        if (lista.vacia) return _NadieEnMora(dias: lista.diasMoraConfig);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(moraProvider),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: lista.datos.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, indice) {
              if (indice == 0) return _Encabezado(lista: lista);
              return _FilaMora(cliente: lista.datos[indice - 1]);
            },
          ),
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.lista});

  final ListaMora lista;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cantidad = lista.datos.length;

    return Container(
      width: double.infinity,
      color: tema.colorScheme.errorContainer,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$cantidad ${cantidad == 1 ? "cliente" : "clientes"} sin pagar '
            'hace más de ${lista.diasMoraConfig} días',
            style: tema.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: tema.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Te deben ${formatearGuaranies(lista.deudaEnMora)} entre todos.',
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaMora extends ConsumerWidget {
  const _FilaMora({required this.cliente});

  final ClienteEnMora cliente;

  /// El color sube de tono con los días: no es lo mismo deber hace un mes que
  /// hace tres.
  Color _colorPorAntiguedad(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    if (cliente.diasSinPagar >= 90) return esquema.error;
    if (cliente.diasSinPagar >= 60) {
      return esquema.error.withValues(alpha: 0.75);
    }
    return esquema.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final color = _colorPorAntiguedad(context);

    // El nombre de la despensa va en el mensaje: el cliente tiene que saber
    // quién le escribe antes de leer que debe plata.
    final nombreDespensa =
        ref.watch(perfilControllerProvider).value?.despensa.nombreComercial ??
        'la despensa';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Text(
          '${cliente.diasSinPagar}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: cliente.diasSinPagar > 99 ? 12 : 14,
          ),
        ),
      ),
      title: Text(cliente.nombre),
      subtitle: Text(
        cliente.nuncaPago
            ? 'Nunca pagó nada'
            : 'Último pago hace ${cliente.diasSinPagar} días',
        style: tema.textTheme.bodySmall?.copyWith(color: color),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatearGuaranies(cliente.saldoActual),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tema.colorScheme.error,
            ),
          ),
          BotonWhatsApp(
            compacto: true,
            telefono: cliente.telefono,
            mensaje: mensajeDeCobranza(
              nombreCliente: cliente.nombre,
              nombreDespensa: nombreDespensa,
              saldo: cliente.saldoActual,
              diasSinPagar: cliente.diasSinPagar,
            ),
          ),
        ],
      ),
      onTap: () => context.go(Rutas.detalleCliente(cliente.id)),
    );
  }
}

class _NadieEnMora extends StatelessWidget {
  const _NadieEnMora({required this.dias});

  final int dias;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_outlined,
              size: 64,
              color: tema.colorScheme.tertiary,
            ),
            const SizedBox(height: 16),
            Text('Nadie está atrasado', style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Ningún cliente lleva más de $dias días sin pagarte.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
