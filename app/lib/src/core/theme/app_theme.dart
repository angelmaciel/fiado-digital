import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color _semilla = Color(0xFF00695C);

  static ThemeData get claro => _construir(Brightness.light);
  static ThemeData get oscuro => _construir(Brightness.dark);

  static ThemeData _construir(Brightness brillo) {
    final esquema = ColorScheme.fromSeed(
      seedColor: _semilla,
      brightness: brillo,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // Los despenseros usan el celular con una mano y a veces con guantes:
          // conviene un objetivo táctil más grande que el mínimo de Material.
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Color con el que se muestra un saldo: rojo si debe, verde si está al día.
Color colorDeSaldo(BuildContext context, int saldo) {
  final esquema = Theme.of(context).colorScheme;
  if (saldo > 0) return esquema.error;
  if (saldo < 0) return esquema.tertiary;
  return esquema.onSurfaceVariant;
}
