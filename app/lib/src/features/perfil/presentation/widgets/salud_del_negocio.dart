import 'package:flutter/material.dart';

import '../../../../core/utils/guaranies.dart';
import '../../domain/resumen_despensa.dart';

/// El bloque que contesta "¿mi negocio va bien o mal?".
///
/// La pregunta no la responde cuánta plata hay en la calle —una despensa con
/// mucha deuda pero que cobra todos los meses está sana— sino la relación entre
/// lo que se fía y lo que se cobra.
class SaludDelNegocioCard extends StatelessWidget {
  const SaludDelNegocioCard({required this.resumen, super.key});

  final ResumenDespensa resumen;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;

    final (:color, :fondo, :icono, :titulo, :explicacion) = _veredicto(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Plata en la calle: el número que el despensero ya tiene en la cabeza.
        Card(
          margin: EdgeInsets.zero,
          color: esquema.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Plata en la calle',
                  style: tema.textTheme.labelLarge?.copyWith(
                    color: esquema.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatearGuaranies(resumen.deudaTotal),
                    style: tema.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: esquema.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  resumen.clientesConDeuda == 0
                      ? 'Nadie te debe nada'
                      : 'Repartida entre ${resumen.clientesConDeuda} '
                            '${resumen.clientesConDeuda == 1 ? "cliente" : "clientes"}',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: esquema.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // El veredicto, en una frase.
        Card(
          margin: EdgeInsets.zero,
          color: fondo,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icono, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        titulo,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(explicacion, style: tema.textTheme.bodyMedium),
                if (resumen.tasaRecuperacion != null) ...[
                  const SizedBox(height: 14),
                  _BarraRecuperacion(
                    porcentaje: resumen.tasaRecuperacion!,
                    color: color,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // El detalle del mes, para quien quiera ver los números.
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _FilaDelMes(
                  etiqueta: 'Fiaste este mes',
                  monto: resumen.esteMes.fiado,
                  montoAnterior: resumen.mesPasado.fiado,
                  icono: Icons.add_shopping_cart,
                  color: esquema.error,
                ),
                const Divider(height: 20),
                _FilaDelMes(
                  etiqueta: 'Cobraste este mes',
                  monto: resumen.esteMes.cobrado,
                  montoAnterior: resumen.mesPasado.cobrado,
                  icono: Icons.payments_outlined,
                  color: esquema.tertiary,
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        resumen.esteMes.variacionDeuda >= 0
                            ? 'La deuda creció'
                            : 'La deuda bajó',
                        style: tema.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      formatearGuaranies(resumen.esteMes.variacionDeuda.abs()),
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: resumen.esteMes.variacionDeuda >= 0
                            ? esquema.error
                            : esquema.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  ({
    Color color,
    Color fondo,
    IconData icono,
    String titulo,
    String explicacion,
  })
  _veredicto(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final tasa = resumen.tasaRecuperacion;
    final cambio = resumen.cambioEnRecuperacion;

    // Se agrega al final de la explicación si hay mes anterior con qué comparar.
    final comparacion = switch (cambio) {
      null => '',
      0 => ' Igual que el mes pasado.',
      final c when c > 0 => ' Mejoraste $c puntos contra el mes pasado.',
      final c => ' Empeoraste ${c.abs()} puntos contra el mes pasado.',
    };

    return switch (resumen.salud) {
      SaludDelNegocio.sinDatos => (
        color: esquema.onSurfaceVariant,
        fondo: esquema.surfaceContainerHighest,
        icono: Icons.hourglass_empty,
        titulo: 'Todavía no fiaste nada este mes',
        explicacion:
            'Cuando empieces a anotar fiados y pagos vas a ver acá si el '
            'negocio va bien o mal.',
      ),
      SaludDelNegocio.bien => (
        color: esquema.tertiary,
        fondo: esquema.tertiaryContainer,
        icono: Icons.trending_down,
        titulo: 'Vas bien: cobrás $tasa% de lo que fiás',
        explicacion:
            'Estás cobrando más de lo que fiás, así que la plata en la calle '
            'está bajando.$comparacion',
      ),
      SaludDelNegocio.justo => (
        color: esquema.onSurfaceVariant,
        fondo: esquema.surfaceContainerHighest,
        icono: Icons.trending_flat,
        titulo: 'Vas justo: cobrás $tasa% de lo que fiás',
        explicacion:
            'Lo que fiás y lo que cobrás están casi empatados. Es sostenible, '
            'pero no te deja margen.$comparacion',
      ),
      SaludDelNegocio.mal => (
        color: esquema.error,
        fondo: esquema.errorContainer,
        icono: Icons.trending_up,
        titulo: 'Ojo: cobrás solo $tasa% de lo que fiás',
        explicacion:
            'Cada mes queda más plata en la calle y menos en el cajón. '
            'Conviene apretar la cobranza de los que más deben.$comparacion',
      ),
    };
  }
}

/// Barra que compara lo cobrado contra lo fiado. La marca del 100% es la
/// referencia: llegar ahí significa cobrar todo lo que se fió en el mes.
class _BarraRecuperacion extends StatelessWidget {
  const _BarraRecuperacion({required this.porcentaje, required this.color});

  final int porcentaje;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    // La escala llega hasta 120% para que un mes bueno se vea pasar la marca.
    final proporcion = (porcentaje / 120).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, restricciones) {
            final marca100 = restricciones.maxWidth * (100 / 120);

            return SizedBox(
              // 10 de barra + 12 de separación + el alto del "100%". Con 22
              // entraba la barra pero la etiqueta quedaba cortada al medio.
              height: 28,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: SizedBox(
                        width: restricciones.maxWidth,
                        child: LinearProgressIndicator(
                          value: proporcion,
                          minHeight: 10,
                          backgroundColor: tema.colorScheme.surface,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: marca100 - 1,
                    top: 0,
                    child: Container(
                      width: 2,
                      height: 10,
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Positioned(
                    left: marca100 - 22,
                    top: 12,
                    child: Text(
                      '100%',
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FilaDelMes extends StatelessWidget {
  const _FilaDelMes({
    required this.etiqueta,
    required this.monto,
    required this.montoAnterior,
    required this.icono,
    required this.color,
  });

  final String etiqueta;
  final int monto;
  final int montoAnterior;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Row(
      children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta, style: tema.textTheme.bodyMedium),
              Text(
                'Mes pasado: ${formatearGuaranies(montoAnterior)}',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          formatearGuaranies(monto),
          style: tema.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
