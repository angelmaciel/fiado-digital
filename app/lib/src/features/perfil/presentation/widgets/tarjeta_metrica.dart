import 'package:flutter/material.dart';

/// Tarjeta de un número grande con su etiqueta. La unidad de construcción del
/// panel: el despensero tiene que poder leer el dato de un vistazo, sin
/// interpretar un gráfico.
class TarjetaMetrica extends StatelessWidget {
  const TarjetaMetrica({
    required this.etiqueta,
    required this.valor,
    this.detalle,
    this.icono,
    this.colorValor,
    super.key,
  });

  final String etiqueta;
  final String valor;
  final String? detalle;
  final IconData? icono;
  final Color? colorValor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (icono != null) ...[
                  Icon(
                    icono,
                    size: 16,
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    etiqueta,
                    style: tema.textTheme.labelMedium?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                valor,
                style: tema.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorValor,
                ),
              ),
            ),
            if (detalle != null) ...[
              const SizedBox(height: 4),
              Text(
                detalle!,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Barra de proporción simple. Se prefiere a un gráfico de torta porque una
/// sola comparación (parte contra total) se lee más rápido así.
class BarraProporcion extends StatelessWidget {
  const BarraProporcion({required this.porcentaje, this.color, super.key});

  final int porcentaje;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: (porcentaje.clamp(0, 100)) / 100,
        minHeight: 8,
        backgroundColor: tema.colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(color ?? tema.colorScheme.primary),
      ),
    );
  }
}
