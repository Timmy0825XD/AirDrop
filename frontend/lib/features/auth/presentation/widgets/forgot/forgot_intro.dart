import 'package:flutter/material.dart';

import 'forgot_header.dart';
import 'forgot_key_badge.dart';

/// Intro de "olvidé mi contraseña": flecha de volver, insignia animada
/// y la explicación de qué contacto pedir.
class ForgotIntro extends StatelessWidget {
  const ForgotIntro({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ForgotHeader(onBack: onBack),
        const SizedBox(height: 24),
        const Center(child: ForgotKeyBadge()),
        const SizedBox(height: 20),
        Text(
          'Ingresa el correo de tu cuenta. Ahí llega el código '
          'para restablecer la contraseña.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
