import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import 'login_button.dart';
import 'login_field.dart';
import 'login_palette.dart';

/// Los dos campos del login, el enlace de recuperación y el botón.
class LoginCredentials extends StatelessWidget {
  const LoginCredentials({
    super.key,
    required this.contactController,
    required this.passwordController,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.validators,
    this.isLoading = false,
  });

  final TextEditingController contactController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final LoginFieldValidators validators;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginField(
          label: 'Correo',
          hint: 'nombre@correo.com',
          controller: contactController,
          keyboardType: TextInputType.emailAddress,
          maxLength: FieldLimits.email,
          textInputAction: TextInputAction.next,
          validator: validators.contact,
          onChanged: validators.onChanged,
        ),
        const SizedBox(height: 16),
        LoginField(
          label: 'Contraseña',
          hint: 'Tu contraseña',
          controller: passwordController,
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          maxLength: FieldLimits.passwordMax,
          textInputAction: TextInputAction.done,
          validator: validators.password,
          onChanged: validators.onChanged,
        ),
        _ForgotLink(onPressed: onForgotPassword),
        const SizedBox(height: 4),
        LoginButton(
          label: 'Iniciar sesión',
          isLoading: isLoading,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

class _ForgotLink extends StatelessWidget {
  const _ForgotLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = LoginPalette.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          minimumSize: const Size(44, 44),
        ),
        child: const Text('¿Olvidaste tu contraseña?'),
      ),
    );
  }
}

/// Agrupa los validadores del login para no pasarlos uno por uno.
class LoginFieldValidators {
  const LoginFieldValidators({
    required this.contact,
    required this.password,
    required this.onChanged,
  });

  final String? Function(String?)? contact;
  final String? Function(String?)? password;
  final ValueChanged<String> onChanged;
}