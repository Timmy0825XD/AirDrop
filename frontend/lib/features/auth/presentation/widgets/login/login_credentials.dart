import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import 'login_button.dart';
import 'login_field.dart';

/// Los dos campos del login más el enlace de recuperación.
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
          label: 'Acceso de personal',
          hint: 'Correo institucional o celular',
          icon: Icons.contact_mail_outlined,
          controller: contactController,
          keyboardType: TextInputType.text,
          maxLength: FieldLimits.email,
          textInputAction: TextInputAction.next,
          validator: validators.contact,
          onChanged: validators.onChanged,
        ),
        const SizedBox(height: 16),
        LoginField(
          label: 'Clave de seguridad',
          hint: 'Contraseña',
          icon: Icons.lock_outline_rounded,
          controller: passwordController,
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          maxLength: FieldLimits.passwordMax,
          textInputAction: TextInputAction.done,
          validator: validators.password,
          onChanged: validators.onChanged,
        ),
        const SizedBox(height: 20),
        LoginButton(
          label: 'Iniciar sesión',
          isLoading: isLoading,
          onPressed: onSubmit,
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: onForgotPassword,
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ),
      ],
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