import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/local/widgets/aviso_sin_conexion.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/guaranies.dart';
import '../../auth/application/auth_controller.dart';
import '../application/clientes_controller.dart';
import '../domain/cliente.dart';
import 'widgets/form_cliente_sheet.dart';
import 'widgets/lista_mora.dart';

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
    final soloMora = ref.watch(filtroSoloMoraProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go(Rutas.perfil),
            icon: const Icon(Icons.insights_outlined),
            label: const Text('Mi negocio'),
          ),
        ),
        actions: const [_NombreDelDueno(), _BotonCerrarSesion()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(152),
          child: Column(
            children: [
              const AvisoSinConexion(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  enabled: !soloMora,
                  decoration: InputDecoration(
                    hintText: soloMora
                        ? 'El buscador no aplica en la lista de atrasados'
                        : 'Buscar por nombre o teléfono',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (texto) => ref
                      .read(busquedaClientesProvider.notifier)
                      .actualizar(texto),
                ),
              ),
              const _FiltrosDeLista(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      floatingActionButton: soloMora
          ? null
          : FloatingActionButton.extended(
              onPressed: _crearCliente,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Nuevo'),
            ),
      body: soloMora
          ? const ListaMoraView()
          : clientes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _EstadoDeError(
                mensaje: error is ApiException
                    ? error.mensaje
                    : error.toString(),
                alReintentar: () => ref.invalidate(clientesControllerProvider),
              ),
              data: (estado) {
                if (estado.clientes.isEmpty) {
                  return const _ListaVacia();
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(clientesControllerProvider),
                  child: ListView.separated(
                    controller: _scrollCtrl,
                    // Siempre scrollable para que el pull-to-refresh funcione aunque
                    // entren pocos clientes en pantalla.
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount:
                        estado.clientes.length + (estado.cargandoMas ? 1 : 0),
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

/// Nombre del dueño en la barra. Se oculta en pantallas angostas: en un
/// celular chico compite por espacio con el botón de "Mi negocio", y el nombre
/// propio es el dato menos necesario de los dos.
class _NombreDelDueno extends ConsumerWidget {
  const _NombreDelDueno();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = ref.watch(
      authControllerProvider.select((estado) => estado.usuario?.nombre),
    );

    if (nombre == null || nombre.isEmpty) return const SizedBox.shrink();
    if (MediaQuery.sizeOf(context).width < 420) return const SizedBox.shrink();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Text(
          nombre,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _BotonCerrarSesion extends ConsumerWidget {
  const _BotonCerrarSesion();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme.error;

    return IconButton(
      tooltip: 'Cerrar sesión',
      icon: Icon(Icons.logout, color: color),
      onPressed: () => ref.read(authControllerProvider.notifier).cerrarSesion(),
    );
  }
}

/// Alterna entre todos los clientes y solo los atrasados. El contador sale de
/// la misma consulta que alimenta la lista, así que no cuesta una request más.
class _FiltrosDeLista extends ConsumerWidget {
  const _FiltrosDeLista();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soloMora = ref.watch(filtroSoloMoraProvider);
    final enMora = ref.watch(moraProvider).value?.datos.length;

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('Todos'),
              selected: !soloMora,
              onSelected: (_) => ref
                  .read(filtroSoloMoraProvider.notifier)
                  .mostrarSoloMora(false),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              avatar: Icon(
                Icons.schedule,
                size: 16,
                color: soloMora ? null : Theme.of(context).colorScheme.error,
              ),
              label: Text(enMora == null ? 'Atrasados' : 'Atrasados ($enMora)'),
              selected: soloMora,
              onSelected: (_) => ref
                  .read(filtroSoloMoraProvider.notifier)
                  .mostrarSoloMora(true),
            ),
          ],
        ),
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
