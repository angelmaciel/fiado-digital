import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../application/metodos_pago_controller.dart';
import '../domain/metodo_pago.dart';
import 'widgets/form_metodo_pago_sheet.dart';

/// HU-11 — el despensero carga sus datos para cobrar por transferencia.
class MetodosPagoScreen extends ConsumerWidget {
  const MetodosPagoScreen({super.key});

  Future<void> _crear(BuildContext context, WidgetRef ref) async {
    final mensajero = ScaffoldMessenger.of(context);
    final datos = await mostrarFormularioMetodoPago(context);
    if (datos == null) return;

    try {
      await ref
          .read(metodosPagoControllerProvider.notifier)
          .crear(
            tipo: datos.tipo,
            titular: datos.titular,
            banco: datos.banco,
            alias: datos.alias,
            numeroCuenta: datos.numeroCuenta,
            nota: datos.nota,
            esPrincipal: datos.esPrincipal,
          );
      mensajero.showSnackBar(
        const SnackBar(content: Text('Método de pago agregado.')),
      );
    } on ApiException catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metodos = ref.watch(metodosPagoControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Rutas.perfil),
        ),
        title: const Text('Cómo me pagan'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _crear(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: metodos.when(
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
          if (lista.isEmpty) return const _SinMetodos();

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: lista.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, indice) {
              if (indice == 0) return const _Explicacion();
              return _FilaMetodo(metodo: lista[indice - 1]);
            },
          );
        },
      ),
    );
  }
}

/// Aclara que la app no cobra nada: es un dato que el despensero comparte.
class _Explicacion extends StatelessWidget {
  const _Explicacion();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      color: tema.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: tema.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Estos datos se los pasás al cliente para que te transfiera. '
              'La app no recibe ni mueve plata: cuando te pague, registrás '
              'el pago vos.',
              style: tema.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaMetodo extends ConsumerWidget {
  const _FilaMetodo({required this.metodo});

  final MetodoPago metodo;

  IconData get _icono => switch (metodo.tipo) {
    TipoMetodoPago.transferencia => Icons.account_balance_outlined,
    TipoMetodoPago.alias => Icons.alternate_email,
    TipoMetodoPago.billeteraDigital => Icons.account_balance_wallet_outlined,
  };

  Future<void> _editar(BuildContext context, WidgetRef ref) async {
    final mensajero = ScaffoldMessenger.of(context);
    final datos = await mostrarFormularioMetodoPago(context, existente: metodo);
    if (datos == null) return;

    try {
      await ref
          .read(metodosPagoControllerProvider.notifier)
          .actualizar(
            metodo.id,
            tipo: datos.tipo,
            titular: datos.titular,
            // Cadena vacía = borrar el dato, igual que con el teléfono.
            banco: datos.banco ?? '',
            alias: datos.alias ?? '',
            numeroCuenta: datos.numeroCuenta ?? '',
            nota: datos.nota ?? '',
            esPrincipal: datos.esPrincipal,
          );
      mensajero.showSnackBar(const SnackBar(content: Text('Datos guardados.')));
    } on ApiException catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  Future<void> _eliminar(BuildContext context, WidgetRef ref) async {
    final mensajero = ScaffoldMessenger.of(context);

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Borrar este método de pago?'),
        content: Text('${metodo.tipo.etiqueta} · ${metodo.datoPrincipal}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await ref
          .read(metodosPagoControllerProvider.notifier)
          .eliminar(metodo.id);
    } on ApiException catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);

    return ListTile(
      leading: Icon(_icono),
      title: Row(
        children: [
          Flexible(child: Text(metodo.tipo.etiqueta)),
          if (metodo.esPrincipal) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tema.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'principal',
                style: tema.textTheme.labelSmall?.copyWith(
                  color: tema.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metodo.banco != null) Text(metodo.banco!),
          Text(metodo.datoPrincipal),
          Text(metodo.titular, style: tema.textTheme.bodySmall),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (opcion) => switch (opcion) {
          'copiar' => _copiar(context, ref),
          'editar' => _editar(context, ref),
          _ => _eliminar(context, ref),
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'copiar', child: Text('Copiar datos')),
          PopupMenuItem(value: 'editar', child: Text('Editar')),
          PopupMenuItem(value: 'borrar', child: Text('Borrar')),
        ],
      ),
    );
  }

  void _copiar(BuildContext context, WidgetRef ref) {
    Clipboard.setData(ClipboardData(text: metodo.comoTexto()));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Datos copiados.')));
  }
}

class _SinMetodos extends StatelessWidget {
  const _SinMetodos();

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
              Icons.account_balance_outlined,
              size: 64,
              color: tema.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('Sin métodos de pago', style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Cargá tu cuenta o billetera para poder pasársela a los clientes '
              'que quieran pagarte por transferencia.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
