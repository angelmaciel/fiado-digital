import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_storage.dart';
import '../../auth/application/auth_controller.dart';
import '../data/perfil_api.dart';
import '../domain/despensa.dart';
import '../domain/resumen_despensa.dart';

/// Datos que muestra la pantalla de perfil: la despensa y su resumen.
class PerfilState {
  const PerfilState({required this.despensa, required this.resumen});

  final Despensa despensa;
  final ResumenDespensa resumen;
}

class PerfilController extends AsyncNotifier<PerfilState> {
  @override
  Future<PerfilState> build() async {
    // Igual que la lista de clientes: atado a la despensa activa, para que un
    // cambio de cuenta no deje el perfil anterior en pantalla.
    ref.watch(
      authControllerProvider.select((estado) => estado.usuario?.despensaId),
    );

    final api = ref.read(perfilApiProvider);
    // En paralelo: son dos consultas independientes y así la pantalla no
    // espera una detrás de la otra.
    final (despensa, resumen) = await (
      api.obtenerDespensa(),
      api.obtenerResumen(),
    ).wait;

    return PerfilState(despensa: despensa, resumen: resumen);
  }

  Future<void> actualizarNombreDelUsuario(String nombre) async {
    await ref.read(perfilApiProvider).actualizarNombre(nombre);
    // El nombre vive en el estado de auth, no acá: se refresca desde ahí.
    await ref.read(authControllerProvider.notifier).refrescarUsuario();
  }

  Future<void> actualizarDespensa({
    String? nombreComercial,
    int? diasMoraConfig,
  }) async {
    await ref
        .read(perfilApiProvider)
        .actualizarDespensa(
          nombreComercial: nombreComercial,
          diasMoraConfig: diasMoraConfig,
        );
    ref.invalidateSelf();
  }

  Future<String> cambiarPassword({
    required String passwordActual,
    required String nuevaPassword,
  }) async {
    final refreshToken = await ref
        .read(tokenStorageProvider)
        .leerRefreshToken();
    return ref
        .read(perfilApiProvider)
        .cambiarPassword(
          passwordActual: passwordActual,
          nuevaPassword: nuevaPassword,
          refreshToken: refreshToken,
        );
  }
}

final perfilControllerProvider =
    AsyncNotifierProvider<PerfilController, PerfilState>(PerfilController.new);
