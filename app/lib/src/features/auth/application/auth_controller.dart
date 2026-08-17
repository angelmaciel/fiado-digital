import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/eventos_sesion.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_api.dart';
import '../data/google_auth_service.dart';
import '../domain/sesion.dart';
import '../domain/usuario.dart';

enum EstadoSesion {
  /// Todavía no sabemos si hay tokens guardados de una sesión anterior.
  verificando,
  sinSesion,

  /// Autenticado pero sin despensa: falta el onboarding.
  necesitaOnboarding,
  autenticado,
}

class AuthState {
  const AuthState({
    this.estado = EstadoSesion.verificando,
    this.usuario,
    this.error,
    this.procesando = false,
    this.requiereVerificarEmail = false,
  });

  final EstadoSesion estado;
  final Usuario? usuario;
  final String? error;

  /// Hay una operación de login/logout en curso: la UI bloquea el botón.
  final bool procesando;

  /// El último intento de login falló porque falta verificar el correo; la
  /// pantalla usa esto para redirigir a la del código en vez de mostrar el error.
  final bool requiereVerificarEmail;

  AuthState copyWith({
    EstadoSesion? estado,
    Usuario? usuario,
    String? error,
    bool? procesando,
    bool requiereVerificarEmail = false,
    bool limpiarError = false,
    bool limpiarUsuario = false,
  }) {
    return AuthState(
      estado: estado ?? this.estado,
      usuario: limpiarUsuario ? null : (usuario ?? this.usuario),
      error: limpiarError ? null : (error ?? this.error),
      procesando: procesando ?? this.procesando,
      requiereVerificarEmail: requiereVerificarEmail,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // El interceptor avisa por acá cuando el refresh token dejó de servir.
    ref.listen(eventosSesionProvider, (_, _) => _limpiarSesionLocal());

    // En Web el login lo dispara el botón de Google, que no devuelve nada al
    // widget: el resultado llega por este stream. En Android no se escucha
    // porque `authenticate()` ya devuelve la cuenta y emite además el evento,
    // lo que dispararía el login dos veces.
    if (AppConfig.usaBotonRenderizadoDeGoogle) {
      final suscripcion = _google.idTokensDelBotonWeb.listen(
        _completarLoginConIdToken,
      );
      ref.onDispose(suscripcion.cancel);
    }

    Future.microtask(_restaurarSesion);
    return const AuthState();
  }

  AuthApi get _api => ref.read(authApiProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);
  GoogleAuthService get _google => ref.read(googleAuthServiceProvider);

  /// Al abrir la app: si hay tokens guardados, se valida contra el backend.
  /// Si el access token venció, el interceptor lo renueva solo.
  Future<void> _restaurarSesion() async {
    final token = await _storage.leerAccessToken();

    if (token == null) {
      state = const AuthState(estado: EstadoSesion.sinSesion);
      return;
    }

    try {
      final usuario = await _api.obtenerUsuarioActual();
      state = AuthState(estado: _estadoSegun(usuario), usuario: usuario);
    } on ApiException {
      await _storage.limpiar();
      state = const AuthState(estado: EstadoSesion.sinSesion);
    }
  }

  Future<void> iniciarSesionConGoogle() async {
    state = state.copyWith(procesando: true, limpiarError: true);

    try {
      if (AppConfig.usaFlujoDeNavegador) {
        final tokens = await _google.loginConNavegador();
        await _storage.guardarTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
        final usuario = await _api.obtenerUsuarioActual();
        state = AuthState(estado: _estadoSegun(usuario), usuario: usuario);
        return;
      }

      final idToken = await _google.obtenerIdToken();
      await _canjearIdTokenPorSesion(idToken);
    } on LoginCanceladoException {
      state = state.copyWith(procesando: false);
    } on ApiException catch (e) {
      state = state.copyWith(procesando: false, error: e.mensaje);
    } catch (e) {
      state = state.copyWith(procesando: false, error: e.toString());
    }
  }

  /// Entrada del login por botón renderizado (Web): el token llega solo, sin
  /// que nadie haya llamado a `iniciarSesionConGoogle`.
  Future<void> _completarLoginConIdToken(String idToken) async {
    state = state.copyWith(procesando: true, limpiarError: true);

    try {
      await _canjearIdTokenPorSesion(idToken);
    } on ApiException catch (e) {
      state = state.copyWith(procesando: false, error: e.mensaje);
    }
  }

  Future<void> _canjearIdTokenPorSesion(String idToken) async {
    await _guardarSesion(await _api.loginConGoogle(idToken));
  }

  // ---------------------------------------------------------------------------
  // Correo y contraseña
  // ---------------------------------------------------------------------------

  /// Alta de cuenta. No inicia sesión: devuelve el mensaje del backend para que
  /// la pantalla mande al usuario a tipear el código.
  Future<String?> registrar({
    required String nombre,
    required String email,
    required String password,
  }) async {
    return _ejecutar(
      () => _api.registrar(nombre: nombre, email: email, password: password),
    );
  }

  /// Devuelve `true` si entró. Si la cuenta existe pero falta verificar el
  /// correo, deja el error cargado y responde `false` con
  /// `ultimoErrorRequiereVerificacion` en true para que la UI redirija.
  Future<bool> iniciarSesionConEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(procesando: true, limpiarError: true);

    try {
      final sesion = await _api.loginConEmail(email: email, password: password);
      await _guardarSesion(sesion);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        procesando: false,
        error: e.mensaje,
        requiereVerificarEmail: e.requiereVerificarEmail,
      );
      return false;
    }
  }

  Future<bool> verificarEmail({
    required String email,
    required String codigo,
  }) async {
    state = state.copyWith(procesando: true, limpiarError: true);

    try {
      await _guardarSesion(
        await _api.verificarEmail(email: email, codigo: codigo),
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(procesando: false, error: e.mensaje);
      return false;
    }
  }

  Future<String?> reenviarCodigo(String email) async {
    return _ejecutar(() => _api.reenviarCodigo(email));
  }

  Future<String?> recuperarPassword(String email) async {
    return _ejecutar(() => _api.recuperarPassword(email));
  }

  Future<bool> restablecerPassword({
    required String email,
    required String codigo,
    required String nuevaPassword,
  }) async {
    state = state.copyWith(procesando: true, limpiarError: true);

    try {
      await _guardarSesion(
        await _api.restablecerPassword(
          email: email,
          codigo: codigo,
          nuevaPassword: nuevaPassword,
        ),
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(procesando: false, error: e.mensaje);
      return false;
    }
  }

  /// Envuelve las operaciones que solo devuelven un mensaje: marca `procesando`,
  /// guarda el error si falla y devuelve null.
  Future<String?> _ejecutar(Future<String> Function() operacion) async {
    state = state.copyWith(procesando: true, limpiarError: true);

    try {
      final mensaje = await operacion();
      state = state.copyWith(procesando: false);
      return mensaje;
    } on ApiException catch (e) {
      state = state.copyWith(procesando: false, error: e.mensaje);
      return null;
    }
  }

  Future<void> _guardarSesion(Sesion sesion) async {
    await _storage.guardarTokens(
      accessToken: sesion.accessToken,
      refreshToken: sesion.refreshToken,
    );

    state = AuthState(
      estado: _estadoSegun(sesion.usuario),
      usuario: sesion.usuario,
    );
  }

  /// Completa el onboarding creando la despensa del dueño.
  Future<void> crearDespensa({
    required String nombreComercial,
    int? diasMoraConfig,
  }) async {
    state = state.copyWith(procesando: true, limpiarError: true);

    try {
      final usuario = await _api.crearDespensa(
        nombreComercial: nombreComercial,
        diasMoraConfig: diasMoraConfig,
      );
      state = AuthState(estado: _estadoSegun(usuario), usuario: usuario);
    } on ApiException catch (e) {
      state = state.copyWith(procesando: false, error: e.mensaje);
    }
  }

  Future<void> cerrarSesion() async {
    state = state.copyWith(procesando: true, limpiarError: true);

    final refreshToken = await _storage.leerRefreshToken();
    if (refreshToken != null) {
      await _api.cerrarSesion(refreshToken);
    }

    await _google.cerrarSesionDeGoogle();
    await _limpiarSesionLocal();
  }

  Future<void> _limpiarSesionLocal() async {
    await _storage.limpiar();
    state = const AuthState(estado: EstadoSesion.sinSesion);
  }

  EstadoSesion _estadoSegun(Usuario usuario) => usuario.tieneDespensa
      ? EstadoSesion.autenticado
      : EstadoSesion.necesitaOnboarding;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
