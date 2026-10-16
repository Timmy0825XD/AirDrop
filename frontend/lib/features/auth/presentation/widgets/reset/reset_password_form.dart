import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../auth_field.dart';
import 'reset_match_icon.dart';
import 'reset_password_strength.dart';

/// Título y a qué correo llegó el código.
class ResetHeading extends StatelessWidget {
  const ResetHeading({super.key, required this.contactLabel});

  final String contactLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('Nueva contraseña', style: theme.textTheme.displayMedium),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'Escribe el código que enviamos a ',
            children: [
              TextSpan(
                text: contactLabel,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: ' y elige tu nueva contraseña.'),
            ],
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Nueva contraseña con su medidor y la confirmación con el check.
class ResetPasswordFields extends StatelessWidget {
  const ResetPasswordFields({
    super.key,
    required this.password,
    required this.confirm,
    required this.errors,
    required this.shakeCount,
    required this.showPassword,
    required this.onTogglePassword,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController password;
  final TextEditingController confirm;

  /// Error de la nueva contraseña y de la confirmación, en ese orden.
  final (String?, String?) errors;
  final int shakeCount;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthField(
          label: 'Nueva contraseña',
          hint: '8 a 72 caracteres',
          icon: Icons.lock_outline_rounded,
          controller: password,
          errorText: errors.$1,
          shakeCount: shakeCount,
          obscureText: !showPassword,
          maxLength: FieldLimits.passwordMax,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: onChanged,
          suffix: AuthPasswordToggle(
            visible: showPassword,
            onPressed: onTogglePassword,
          ),
        ),
        ResetPasswordStrength(controller: password),
        const SizedBox(height: 18),
        _ConfirmField(fields: this),
      ],
    );
  }
}

/// La confirmación, con el check cuando coincide con la nueva contraseña.
class _ConfirmField extends StatelessWidget {
  const _ConfirmField({required this.fields});

  final ResetPasswordFields fields;

  @override
  Widget build(BuildContext context) {
    final f = fields;
    final match =
        f.confirm.text.isNotEmpty && f.confirm.text == f.password.text;
    return AuthField(
      label: 'Confirmar contraseña',
      hint: 'Repite la nueva contraseña',
      icon: Icons.lock_outline_rounded,
      controller: f.confirm,
      errorText: f.errors.$2,
      shakeCount: f.shakeCount,
      obscureText: !f.showPassword,
      maxLength: FieldLimits.passwordMax,
      autofillHints: const [AutofillHints.newPassword],
      onChanged: f.onChanged,
      onSubmitted: (_) => f.onSubmit(),
      suffix: ResetMatchIcon(match: match),
    );
  }
}
