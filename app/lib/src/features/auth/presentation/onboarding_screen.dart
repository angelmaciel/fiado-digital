import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';

/// Paso que completa el login: el primer ingreso con Google crea el usuario
/// pero todavía no la despensa, porque en ese momento no sabemos su nombre.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _diasMoraCtrl = TextEditingController(text: '30');

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _diasMoraCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(authControllerProvider.notifier)
        .crearDespensa(
          nombreComercial: _nombreCtrl.text.trim(),
          diasMoraConfig: int.tryParse(_diasMoraCtrl.text.trim()),
        );
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(authControllerProvider);
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurá tu despensa'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).cerrarSesion(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '¡Hola${estado.usuario != null ? ', ${estado.usuario!.nombre.split(' ').first}' : ''}!',
                      style: tema.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contanos cómo se llama tu despensa para empezar a cargar clientes.',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _nombreCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la despensa',
                        hintText: 'Despensa Doña Ramona',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      validator: (valor) {
                        final texto = valor?.trim() ?? '';
                        if (texto.length < 2) {
                          return 'Escribí al menos 2 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _diasMoraCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Días para considerar mora',
                        helperText:
                            'Después de cuántos días sin pagar avisamos',
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
                    if (estado.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        estado.error!,
                        style: TextStyle(color: tema.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: estado.procesando ? null : _guardar,
                      child: Text(
                        estado.procesando ? 'Creando…' : 'Crear despensa',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
