import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/guaranies.dart';
import '../../auth/application/auth_controller.dart';
import '../application/clientes_controller.dart';
import '../domain/cliente.dart';
import 'widgets/form_cliente_sheet.dart';

/// HU-02 — listado de clientes con buscador.
class ClientesScreen extends ConsumerStatefulWidget {
  const ClientesScreen({super.key});

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_alScrollear);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_alScrollear);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _alScrollear() {
    final falta =
        _scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels;
    if (falta < 300) {
      ref.read(clientesControllerProvider.notifier).cargarMas();
    }
  }

  Future<void> _crearCliente() async {
    final datos = await mostrarFormularioCliente(context);
    if (datos == null || !mounted) return;

    try {
      await ref
          .read(clientesControllerProvider.notifier)
          .crear(
            nombre: datos.nombre,
            telefono: datos.telefono,
            limiteCredito: datos.limiteCredito,
          );
      _avisar('${datos.nombre} quedó agregado.');
    } on ApiException catch (e) {
      _avisar(e.mensaje, esError: true);
    }
  }

  void _avisar(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientes = ref.watch(clientesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).cerrarSesion(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o teléfono',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (texto) =>
                  ref.read(busquedaClientesProvider.notifier).actualizar(texto),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearCliente,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo'),
      ),
      body: clientes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _EstadoDeError(
          mensaje: error is ApiException ? error.mensaje : error.toString(),
          alReintentar: () => ref.invalidate(clientesControllerProvider),
        ),
        data: (estado) {
          if (estado.clientes.isEmpty) {
            return const _ListaVacia();
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(clientesControllerProvider),
            child: ListView.separated(
              controller: _scrollCtrl,
              // Siempre scrollable para que el pull-to-refresh funcione aunque
              // entren pocos clientes en pantalla.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: estado.clientes.length + (estado.cargandoMas ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, indice) {
                if (indice >= estado.clientes.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _FilaCliente(cliente: estado.clientes[indice]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _FilaCliente extends StatelessWidget {
  const _FilaCliente({required this.cliente});

  final Cliente cliente;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          cliente.nombre.characters.first.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(cliente.nombre),
      subtitle: cliente.telefono != null ? Text(cliente.telefono!) : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatearGuaranies(cliente.saldoActual),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorDeSaldo(context, cliente.saldoActual),
            ),
          ),
          if (cliente.estaAlDia)
            Text('al día', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
      onTap: () => context.go(Rutas.detalleCliente(cliente.id)),
    );
  }
}

class _ListaVacia extends StatelessWidget {
  const _ListaVacia();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Todavía no cargaste clientes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tocá "Nuevo" para agregar al primero.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoDeError extends StatelessWidget {
  const _EstadoDeError({required this.mensaje, required this.alReintentar});

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
