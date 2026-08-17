import 'package:flutter/material.dart';

/// Andamiaje común de las pantallas de entrada: centrado, ancho máximo cómodo
/// de leer y con scroll para que el teclado no tape los campos.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.titulo,
    required this.hijos,
    this.subtitulo,
    this.icono,
    this.mostrarVolver = false,
    super.key,
  });

  final String titulo;
  final String? subtitulo;
  final IconData? icono;
  final bool mostrarVolver;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: mostrarVolver
          ? AppBar(backgroundColor: Colors.transparent)
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (icono != null) ...[
                    Icon(icono, size: 64, color: tema.colorScheme.primary),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: tema.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitulo!,
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  ...hijos,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AvisoDeError extends StatelessWidget {
  const AvisoDeError({required this.mensaje, super.key});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: esquema.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: esquema.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(color: esquema.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de contraseña con el ojo para mostrarla. En un celular, tipear una
/// contraseña larga a ciegas y equivocarse es la principal causa de abandono.
class CampoPassword extends StatefulWidget {
  const CampoPassword({
    required this.controller,
    required this.label,
    this.textInputAction = TextInputAction.done,
    this.validator,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final VoidCallback? onSubmitted;

  @override
  State<CampoPassword> createState() => _CampoPasswordState();
}

class _CampoPasswordState extends State<CampoPassword> {
  bool _oculta = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _oculta,
      textInputAction: widget.textInputAction,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _oculta ? 'Mostrar' : 'Ocultar',
          icon: Icon(
            _oculta ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _oculta = !_oculta),
        ),
      ),
    );
  }
}

/// Validaciones compartidas, iguales a las del backend para que el error salte
/// antes del viaje al servidor.
class ValidacionesAuth {
  const ValidacionesAuth._();

  static String? email(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Escribí tu correo';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto)) {
      return 'Ese correo no parece válido';
    }
    return null;
  }

  static String? passwordNueva(String? valor) {
    final texto = valor ?? '';
    if (texto.length < 8) return 'Al menos 8 caracteres';
    if (texto.length > 128) return 'Máximo 128 caracteres';
    if (texto.trim() != texto) {
      return 'No puede empezar ni terminar con espacios';
    }
    return null;
  }

  static String? codigo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (!RegExp(r'^\d{6}$').hasMatch(texto)) return 'El código tiene 6 dígitos';
    return null;
  }
}
