import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/metodos_pago_api.dart';
import '../domain/metodo_pago.dart';

class MetodosPagoController extends AsyncNotifier<List<MetodoPago>> {
  @override
  Future<List<MetodoPago>> build() async {
    // Atado a la despensa activa, como el resto de los datos.
    final despensaId = ref.watch(
      authControllerProvider.select((estado) => estado.usuario?.despensaId),
    );

    if (despensaId == null) return const [];

    return ref.read(metodosPagoApiProvider).listar();
  }

  Future<void> crear({
    required TipoMetodoPago tipo,
    required String titular,
    String? banco,
    String? alias,
    String? numeroCuenta,
    String? nota,
    bool? esPrincipal,
  }) async {
    await ref
        .read(metodosPagoApiProvider)
        .crear(
          tipo: tipo,
          titular: titular,
          banco: banco,
          alias: alias,
          numeroCuenta: numeroCuenta,
          nota: nota,
          esPrincipal: esPrincipal,
        );
    ref.invalidateSelf();
  }

  Future<void> actualizar(
    String id, {
    TipoMetodoPago? tipo,
    String? titular,
    String? banco,
    String? alias,
    String? numeroCuenta,
    String? nota,
    bool? esPrincipal,
  }) async {
    await ref
        .read(metodosPagoApiProvider)
        .actualizar(
          id,
          tipo: tipo,
          titular: titular,
          banco: banco,
          alias: alias,
          numeroCuenta: numeroCuenta,
          nota: nota,
          esPrincipal: esPrincipal,
        );
    ref.invalidateSelf();
  }

  Future<void> eliminar(String id) async {
    await ref.read(metodosPagoApiProvider).eliminar(id);
    ref.invalidateSelf();
  }
}

final metodosPagoControllerProvider =
    AsyncNotifierProvider<MetodosPagoController, List<MetodoPago>>(
      MetodosPagoController.new,
    );

/// El que se ofrece primero al compartir, o null si no hay ninguno cargado.
final metodoPagoPrincipalProvider = Provider<MetodoPago?>((ref) {
  final metodos = ref.watch(metodosPagoControllerProvider).value;
  if (metodos == null || metodos.isEmpty) return null;

  return metodos.firstWhere((m) => m.esPrincipal, orElse: () => metodos.first);
});
