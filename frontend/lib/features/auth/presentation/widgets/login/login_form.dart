import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../auth_field.dart';
import '../auth_morph_button.dart';
import '../auth_text_link.dart';

/// Eyebrow, título y subtítulo del formulario.
class LoginHeading extends StatelessWidget {
  const LoginHeading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LOGÍSTICA AEROMÉDICA',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text('Inicia sesión', style: theme.textTheme.displayMedium),
        ),
        const SizedBox(height: 6),
        Text(
          'Entra con tu correo y tu contraseña.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Correo y contraseña. Los errores llegan ya validados desde la pantalla.
class LoginFields extends StatelessWidget {
  const LoginFields({
    super.key,
    required this.email,
    required this.password,
    required this.errors,
    required this.shakeCount,
    required this.showPassword,
    required this.onTogglePassword,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController email;
  final TextEditingController password;

  /// Error del correo y de la contraseña, en ese orden (`null` si no hay).
  final (String?, String?) errors;
  final int shakeCount;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AuthField(
          label: 'Correo electrónico',
          hint: 'nombre@correo.com',
          icon: Icons.mail_outline_rounded,
          controller: email,
          errorText: errors.$1,
          shakeCount: shakeCount,
          keyboardType: TextInputType.emailAddress,
          maxLength: FieldLimits.email,
          autofillHints: const [AutofillHints.email],
          onChanged: onChanged,
        ),
        const SizedBox(height: 14),
        _PasswordField(fields: this),
      ],
    );
  }
}

/// La contraseña con el ojo para mostrarla; "listo" en el teclado envía.
class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.fields});

  final LoginFields fields;

  @override
  Widget build(BuildContext context) {
    final f = fields;
    return AuthField(
      label: 'Contraseña',
      hint: 'Tu contraseña',
      icon: Icons.lock_outline_rounded,
      controller: f.password,
      errorText: f.errors.$2,
      shakeCount: f.shakeCount,
      obscureText: !f.showPassword,
      maxLength: FieldLimits.passwordMax,
      autofillHints: const [AutofillHints.password],
      onChanged: f.onChanged,
      onSubmitted: (_) => f.onSubmit(),
      suffix: AuthPasswordToggle(
        visible: f.showPassword,
        onPressed: f.onTogglePassword,
      ),
    );
  }
}

/// "¿Olvidaste tu contraseña?", el botón y el enlace al registro.
class LoginActions extends StatelessWidget {
  const LoginActions({
    super.key,
    required this.buttonKey,
    required this.isLoading,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onRegister,
  });

  /// Marca el botón para que el círculo de salida nazca desde él.
  final GlobalKey buttonKey;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onForgotPassword,
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: AuthMorphButton(
            key: buttonKey,
            label: 'Iniciar sesión',
            loadingLabel: 'Iniciando sesión',
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ),
        const SizedBox(height: 10),
        AuthTextLink(
          question: '¿No tienes cuenta?',
          action: 'Regístrate',
          onPressed: onRegister,
        ),
      ],
    );
  }
}
