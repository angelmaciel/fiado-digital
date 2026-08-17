import 'usuario.dart';

/// Respuesta de `/auth/google`, `/auth/google/callback` y `/auth/refresh`.
class Sesion {
  const Sesion({
    required this.accessToken,
    required this.refreshToken,
    required this.usuario,
    required this.necesitaOnboarding,
  });

  final String accessToken;
  final String refreshToken;
  final Usuario usuario;

  /// El usuario todavía no creó su despensa: hay que mandarlo al onboarding
  /// antes de dejarlo entrar al resto de la app.
  final bool necesitaOnboarding;

  factory Sesion.fromJson(Map<String, dynamic> json) {
    return Sesion(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      usuario: Usuario.fromJson(json['usuario'] as Map<String, dynamic>),
      necesitaOnboarding: json['necesitaOnboarding'] as bool? ?? false,
    );
  }
}
