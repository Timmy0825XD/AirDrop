import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../login/login_button.dart';
import '../login/login_glass_card.dart';
import '../register/register_field.dart';
import 'forgot_intro.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ForgotIntro(onBack: onBack),
        const SizedBox(height: 24),
        _ContactCard(
          contactController: contactController,
          methodChips: methodChips,
          onSubmit: onSubmit,
          hint: hint,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          isLoading: isLoading,
        ),
        const SizedBox(height: 24),
        _ReturnLink(onPressed: onReturnToLogin),
      ],
    );
  }
}

/// La tarjeta de vidrio con el campo de contacto, los chips de método y el
/// botón que envía el código.
class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contactController,
    required this.methodChips,
    required this.onSubmit,
    required this.hint,
    required this.keyboardType,
    required this.validator,
    required this.onChanged,
    required this.isLoading,
  });

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
    return LoginGlassCard(
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
