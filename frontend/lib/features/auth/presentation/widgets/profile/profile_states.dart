import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../login/login_button.dart';

/// Estado sin sesión dentro del perfil: explica qué falta y ofrece
/// volver al login.
class ProfileSignedOut extends StatelessWidget {
  const ProfileSignedOut({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.onSurface.withValues(alpha: 0.08),
                      ),
                      child: Icon(
                        Icons.person_off_outlined,
                        size: 32,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Inicia sesión para ver tu perfil.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  LoginButton(
                    label: 'Ir al login',
                    onPressed: () => context.go('/login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Error de sesión con el mensaje que ya trae `ApiException`.
class ProfileError extends StatelessWidget {
  const ProfileError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}