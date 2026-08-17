enum RolUsuario { dueno, empleado }

enum MetodoAuth { google, emailPassword }

class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.metodoAuth,
    this.despensaId,
  });

  final String id;
  final String nombre;
  final String email;
  final RolUsuario rol;
  final MetodoAuth metodoAuth;
  final String? despensaId;

  bool get tieneDespensa => despensaId != null;

  /// Quien entra con Google no tiene contraseña, así que no se le ofrece
  /// cambiarla.
  bool get usaPassword => metodoAuth == MetodoAuth.emailPassword;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: switch (json['rol'] as String?) {
        'EMPLEADO' => RolUsuario.empleado,
        _ => RolUsuario.dueno,
      },
      metodoAuth: switch (json['metodoAuth'] as String?) {
        'EMAIL_PASSWORD' => MetodoAuth.emailPassword,
        _ => MetodoAuth.google,
      },
      despensaId: json['despensaId'] as String?,
    );
  }
}
