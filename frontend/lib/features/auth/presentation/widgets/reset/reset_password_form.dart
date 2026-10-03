import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/validators.dart';
import '../login/login_alert.dart';
import '../login/login_button.dart';
import '../register/register_field.dart';
import 'reset_match_icon.dart';
import 'reset_password_strength.dart';

/// Formulario de restablecimiento: código, nueva contraseña y su
/// confirmación. Solo pinta; la validación de la confirmación la pasa
/// la pantalla porque compara contra el primer campo.
class ResetPasswordForm extends StatelessWidget {
  const ResetPasswordForm({
    super.key,
    required this.contactLabel,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.codeSection,
    required this.errorMessage,
    required this.onDismissError,
    required this.onSubmit,
    this.confirmValidator,
    this.isLoading = false,
  });

  final String contactLabel;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final Widget codeSection;
  final String? errorMessage;
  final VoidCallback onDismissError;
  final VoidCallback onSubmit;
  final String? Function(String?)? confirmValidator;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResetHeading(contactLabel: contactLabel),
        const SizedBox(height: 24),
        _Alert(message: errorMessage, onDismiss: onDismissError),
        codeSection,
        const SizedBox(height: 24),
        _PasswordFields(
          passwordController: passwordController,
          confirmPasswordController: confirmPasswordController,
          confirmValidator: confirmValidator,
        ),
        const SizedBox(height: 24),
        LoginButton(
          label: 'Actualizar contraseña',
          isLoading: isLoading,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

/// La nueva clave y su confirmación, con el medidor de fuerza entre
/// ellas. La regla de confirmación la pasa la pantalla.
class _PasswordFields extends StatelessWidget {
  const _PasswordFields({
    required this.passwordController,
    required this.confirmPasswordController,
    this.confirmValidator,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? Function(String?)? confirmValidator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegisterField(
          label: 'Nueva contraseña',
          hint: '••••••••••••',
          icon: Icons.key_rounded,
          controller: passwordController,
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          maxLength: FieldLimits.passwordMax,
          textInputAction: TextInputAction.next,
          validator: Validators.password,
        ),
        ResetPasswordStrength(controller: passwordController),
        const SizedBox(height: 16),
        RegisterField(
          label: 'Confirmar contraseña',
          hint: '••••••••••••',
          icon: Icons.password_rounded,
          controller: confirmPasswordController,
          obscureText: true,
          suffix: ResetMatchIcon(
            password: passwordController,
            confirm: confirmPasswordController,
          ),
          keyboardType: TextInputType.visiblePassword,
          maxLength: FieldLimits.passwordMax,
          textInputAction: TextInputAction.done,
          validator: confirmValidator,
        ),
      ],
    );
  }
}

class _ResetHeading extends StatelessWidget {
  const _ResetHeading({required this.contactLabel});

  final String contactLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                size: 16,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'PROTOCOLO DE RECUPERACIÓN',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Nueva contraseña',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ingresa el código de ${FieldLimits.otpDigits} dígitos enviado a '
          '$contactLabel y define tu nueva clave de acceso.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.6),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _Alert extends StatelessWidget {
  const _Alert({required this.message, required this.onDismiss});

  final String? message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final text = message;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: text == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                key: ValueKey(text),
                padding: const EdgeInsets.only(bottom: 16),
                child: LoginAlert(message: text, onDismiss: onDismiss),
              ),
      ),
    );
  }
}