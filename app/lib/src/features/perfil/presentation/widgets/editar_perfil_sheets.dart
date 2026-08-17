import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';
import '../../application/perfil_controller.dart';

/// Contenedor común de los formularios del perfil: título, campos y botón.
/// Se encarga de mostrar el error y el estado de guardado en un solo lugar.
class _HojaDeEdicion extends StatefulWidget {
  const _HojaDeEdicion({
    required this.titulo,
    required this.campos,
    required this.alGuardar,
    required this.formKey,
  });

  final String titulo;
  final List<Widget> campos;
  final GlobalKey<FormState> formKey;

  /// Devuelve el mensaje de éxito, o lanza ApiException.
  final Future<String> Function() alGuardar;

  @override
  State<_HojaDeEdicion> createState() => _HojaDeEdicionState();
}

class _HojaDeEdicionState extends State<_HojaDeEdicion> {
  bool _guardando = false;
  String? _error;

  Future<void> _guardar() async {
    if (!widget.formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    final navigator = Navigator.of(context);
    final mensajero = ScaffoldMessenger.of(context);

    try {
      final mensaje = await widget.alGuardar();
      navigator.pop();
      mensajero.showSnackBar(SnackBar(content: Text(mensaje)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.mensaje;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: widget.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.titulo,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                AvisoDeError(mensaje: _error!),
                const SizedBox(height: 16),
              ],
              ...widget.campos,
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: Text(_guardando ? 'Guardando…' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> editarNombreDelUsuario(
  BuildContext context,
  WidgetRef ref,
  String nombreActual,
) {
  final formKey = GlobalKey<FormState>();
  final ctrl = TextEditingController(text: nombreActual);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _HojaDeEdicion(
      formKey: formKey,
      titulo: 'Mi nombre',
      campos: [
        TextFormField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (valor) {
            final texto = valor?.trim() ?? '';
            if (texto.length < 2) return 'Escribí al menos 2 caracteres';
            if (texto.length > 120) return 'Máximo 120 caracteres';
            return null;
          },
        ),
      ],
      alGuardar: () async {
        await ref
            .read(perfilControllerProvider.notifier)
            .actualizarNombreDelUsuario(ctrl.text.trim());
        return 'Nombre actualizado.';
      },
    ),
  ).whenComplete(ctrl.dispose);
}

Future<void> editarDespensa(BuildContext context, WidgetRef ref) {
  final datos = ref.read(perfilControllerProvider).value;
  if (datos == null) return Future.value();

  final formKey = GlobalKey<FormState>();
  final nombreCtrl = TextEditingController(
    text: datos.despensa.nombreComercial,
  );
  final moraCtrl = TextEditingController(
    text: datos.despensa.diasMoraConfig.toString(),
  );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _HojaDeEdicion(
      formKey: formKey,
      titulo: 'Datos de la despensa',
      campos: [
        TextFormField(
          controller: nombreCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre de la despensa',
            prefixIcon: Icon(Icons.storefront_outlined),
          ),
          validator: (valor) {
            final texto = valor?.trim() ?? '';
            if (texto.length < 2) return 'Escribí al menos 2 caracteres';
            if (texto.length > 160) return 'Máximo 160 caracteres';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: moraCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Días para considerar mora',
            helperText: 'Después de cuántos días sin pagar avisamos',
            prefixIcon: Icon(Icons.event_busy_outlined),
          ),
          validator: (valor) {
            final dias = int.tryParse(valor?.trim() ?? '');
            if (dias == null || dias < 1 || dias > 365) {
              return 'Poné un número entre 1 y 365';
            }
            return null;
          },
        ),
      ],
      alGuardar: () async {
        await ref
            .read(perfilControllerProvider.notifier)
            .actualizarDespensa(
              nombreComercial: nombreCtrl.text.trim(),
              diasMoraConfig: int.tryParse(moraCtrl.text.trim()),
            );
        return 'Datos de la despensa actualizados.';
      },
    ),
  ).whenComplete(() {
    nombreCtrl.dispose();
    moraCtrl.dispose();
  });
}

Future<void> cambiarPassword(BuildContext context, WidgetRef ref) {
  final formKey = GlobalKey<FormState>();
  final actualCtrl = TextEditingController();
  final nuevaCtrl = TextEditingController();
  final repetirCtrl = TextEditingController();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _HojaDeEdicion(
      formKey: formKey,
      titulo: 'Cambiar contraseña',
      campos: [
        CampoPassword(
          controller: actualCtrl,
          label: 'Contraseña actual',
          textInputAction: TextInputAction.next,
          validator: (valor) =>
              (valor ?? '').isEmpty ? 'Escribí tu contraseña actual' : null,
        ),
        const SizedBox(height: 16),
        CampoPassword(
          controller: nuevaCtrl,
          label: 'Nueva contraseña',
          textInputAction: TextInputAction.next,
          validator: ValidacionesAuth.passwordNueva,
        ),
        const SizedBox(height: 16),
        CampoPassword(
          controller: repetirCtrl,
          label: 'Repetir nueva contraseña',
          validator: (valor) =>
              valor != nuevaCtrl.text ? 'Las contraseñas no coinciden' : null,
        ),
        const SizedBox(height: 12),
        Text(
          'Se van a cerrar las sesiones abiertas en otros dispositivos. '
          'Esta se mantiene.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
      alGuardar: () => ref
          .read(perfilControllerProvider.notifier)
          .cambiarPassword(
            passwordActual: actualCtrl.text,
            nuevaPassword: nuevaCtrl.text,
          ),
    ),
  ).whenComplete(() {
    actualCtrl.dispose();
    nuevaCtrl.dispose();
    repetirCtrl.dispose();
  });
}
