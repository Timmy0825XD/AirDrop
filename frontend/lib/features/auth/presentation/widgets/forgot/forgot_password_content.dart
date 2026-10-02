import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../login/login_button.dart';
import '../login/login_glass_card.dart';
import '../register/register_field.dart';
import 'forgot_header.dart';
import 'forgot_key_badge.dart';

/// Contenido de "olvidé mi contraseña": pide el contacto, deja elegir si
/// es correo o celular y envía el código. El texto y el tipo de teclado
/// dependen del método elegido, así que llegan ya resueltos.
class ForgotPasswordContent extends StatelessWidget {
  const ForgotPasswordContent({
    super.key,
    required this.onBack,
    required this.onReturnToLogin,
    required this.contactController,
    required this.methodChips,
    required this.onSubmit,
    required this.hint,
    required this.keyboardType,
    required this.validator,
    required this.onChanged,
    this.isLoading = false,
  });

  final VoidCallback onBack;
  final VoidCallback onReturnToLogin;
  final TextEditingController contactController;
  final Widget methodChips;
  final VoidCallback onSubmit;
  final String hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String> onChanged;
  final bool isLoading;

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
          'Ingresa el correo o celular vinculado a tu cuenta para recibir '
          'el código de verificación.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        LoginGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RegisterField(
                label: 'Identificador de acceso',
                hint: hint,
                icon: Icons.badge_outlined,
                controller: contactController,
                keyboardType: keyboardType,
                maxLength: FieldLimits.email,
                textInputAction: TextInputAction.next,
                validator: validator,
                onChanged: onChanged,
              ),
              const SizedBox(height: 16),
              methodChips,
              const SizedBox(height: 20),
              LoginButton(
                label: 'Enviar código',
                icon: Icons.send_rounded,
                iconFirst: true,
                isLoading: isLoading,
                onPressed: onSubmit,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _ReturnLink(onPressed: onReturnToLogin),
      ],
    );
  }
}

class _ReturnLink extends StatelessWidget {
  const _ReturnLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, size: 16, color: muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text.rich(
                TextSpan(
                  text: 'Recordé mi contraseña · ',
                  children: [
                    TextSpan(
                      text: 'Regresar al inicio',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                style: theme.textTheme.labelMedium?.copyWith(color: muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}