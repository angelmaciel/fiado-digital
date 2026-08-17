enum RolUsuario { dueno, empleado }

class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.despensaId,
  });

  final String id;
  final String nombre;
  final String email;
  final RolUsuario rol;
  final String? despensaId;

  bool get tieneDespensa => despensaId != null;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: switch (json['rol'] as String?) {
        'EMPLEADO' => RolUsuario.empleado,
        _ => RolUsuario.dueno,
      },
      despensaId: json['despensaId'] as String?,
    );
  }
}
