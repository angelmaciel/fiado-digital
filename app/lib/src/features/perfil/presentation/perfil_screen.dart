import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/guaranies.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/usuario.dart';
import '../application/perfil_controller.dart';
import '../domain/resumen_despensa.dart';
import 'widgets/editar_perfil_sheets.dart';
import 'widgets/tarjeta_metrica.dart';

/// Perfil del dueño y estado del negocio.
class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilControllerProvider);
    final usuario = ref.watch(authControllerProvider).usuario;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Rutas.clientes),
        ),
        title: const Text('Mi negocio'),
      ),
      body: perfil.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Error(
          mensaje: error is ApiException ? error.mensaje : error.toString(),
          alReintentar: () => ref.invalidate(perfilControllerProvider),
        ),
        data: (datos) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(perfilControllerProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _Encabezado(
                usuario: usuario,
                nombreDespensa: datos.despensa.nombreComercial,
              ),
              const SizedBox(height: 24),
              _Salud(resumen: datos.resumen),
              const SizedBox(height: 24),
              Text('Clientes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _Clientes(resumen: datos.resumen),
              const SizedBox(height: 24),
              if (datos.resumen.mayoresDeudores.isNotEmpty) ...[
                Text(
                  'Quiénes más deben',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _MayoresDeudores(resumen: datos.resumen),
                const SizedBox(height: 24),
              ],
              Text('Ajustes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _Ajustes(
                usuario: usuario,
                diasMora: datos.despensa.diasMoraConfig,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.usuario, required this.nombreDespensa});

  final Usuario? usuario;
  final String nombreDespensa;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          child: Text(
            (usuario?.nombre.trim().isNotEmpty ?? false)
                ? usuario!.nombre.trim().characters.first.toUpperCase()
                : '?',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombreDespensa,
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(usuario?.nombre ?? '', style: tema.textTheme.bodyMedium),
              Text(
                usuario?.email ?? '',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// El bloque que contesta "¿voy bien o mal?".
class _Salud extends StatelessWidget {
  const _Salud({required this.resumen});

  final ResumenDespensa resumen;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    if (resumen.sinDatos) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.insights_outlined,
                size: 40,
                color: tema.colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'Todavía no hay nada que medir',
                style: tema.textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Cargá tus clientes y empezá a anotar fiados para ver cómo va tu negocio.',
                style: tema.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: tema.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Plata en la calle',
                  style: tema.textTheme.labelLarge?.copyWith(
                    color: tema.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatearGuaranies(resumen.deudaTotal),
                    style: tema.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tema.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  resumen.clientesConDeuda == 0
                      ? 'Nadie te debe nada'
                      : 'Repartida entre ${resumen.clientesConDeuda} '
                            '${resumen.clientesConDeuda == 1 ? "cliente" : "clientes"}',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Aviso honesto: sin movimientos, la mitad de la historia falta.
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tema.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.schedule,
                size: 18,
                color: tema.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cuánto fiaste y cuánto cobraste este mes se va a poder medir '
                  'cuando empieces a registrar fiados y pagos.',
                  style: tema.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Clientes extends StatelessWidget {
  const _Clientes({required this.resumen});

  final ResumenDespensa resumen;

  @override
  Widget build(BuildContext context) {
    final variacion = resumen.variacionAltas;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TarjetaMetrica(
                etiqueta: 'Total',
                valor: '${resumen.totalClientes}',
                icono: Icons.groups_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TarjetaMetrica(
                etiqueta: 'Nuevos este mes',
                valor: '${resumen.nuevosEsteMes}',
                icono: Icons.person_add_alt,
                detalle: variacion == null
                    ? 'sin comparación'
                    : '${variacion >= 0 ? "+" : ""}$variacion% vs. mes pasado',
                colorValor: variacion == null || variacion == 0
                    ? null
                    : (variacion > 0
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TarjetaMetrica(
                etiqueta: 'Te deben',
                valor: '${resumen.clientesConDeuda}',
                icono: Icons.pending_actions_outlined,
                colorValor: resumen.clientesConDeuda > 0
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TarjetaMetrica(
                etiqueta: 'Al día',
                valor: '${resumen.clientesAlDia}',
                icono: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        if (resumen.limitesExcedidos > 0) ...[
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            color: Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              title: Text(
                '${resumen.limitesExcedidos} '
                '${resumen.limitesExcedidos == 1 ? "cliente pasó" : "clientes pasaron"} '
                'su límite de crédito',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MayoresDeudores extends StatelessWidget {
  const _MayoresDeudores({required this.resumen});

  final ResumenDespensa resumen;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final mayor = resumen.mayoresDeudores.first.saldoActual;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final deudor in resumen.mayoresDeudores) ...[
              InkWell(
                onTap: () => context.go(Rutas.detalleCliente(deudor.id)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(deudor.nombre)),
                          Text(
                            formatearGuaranies(deudor.saldoActual),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorDeSaldo(context, deudor.saldoActual),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      BarraProporcion(
                        porcentaje: mayor > 0
                            ? ((deudor.saldoActual / mayor) * 100).round()
                            : 0,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (resumen.clientesConDeuda > 3) ...[
              const Divider(height: 24),
              Text(
                'Los 3 que más deben concentran el ${resumen.concentracionTop3}% '
                'de todo lo que te deben.',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: resumen.concentracionTop3 >= 70
                      ? tema.colorScheme.error
                      : tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Ajustes extends ConsumerWidget {
  const _Ajustes({required this.usuario, required this.diasMora});

  final Usuario? usuario;
  final int diasMora;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mi nombre'),
            subtitle: Text(usuario?.nombre ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                editarNombreDelUsuario(context, ref, usuario?.nombre ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Datos de la despensa'),
            subtitle: Text('Mora a los $diasMora días'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => editarDespensa(context, ref),
          ),
          // Los usuarios de Google no tienen contraseña que cambiar.
          if (usuario != null && usuario!.usaPassword)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Cambiar contraseña'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => cambiarPassword(context, ref),
            ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Cerrar sesión',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () =>
                ref.read(authControllerProvider.notifier).cerrarSesion(),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.mensaje, required this.alReintentar});

  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: alReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
