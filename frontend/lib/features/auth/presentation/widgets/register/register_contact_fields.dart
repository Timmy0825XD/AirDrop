import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import 'register_field.dart';
import 'register_field_validators.dart';

/// Celular, correo y contraseña del registro, en ese orden. Vive separado
/// de `RegisterFields` porque son los tres campos que comparten validador
/// de contacto; el nombre y el documento se quedan con la pantalla.
class RegisterContactFields extends StatelessWidget {
  const RegisterContactFields({
    super.key,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.validators,
  });

  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final RegisterFieldValidators validators;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegisterField(
          label: 'Celular de contacto',
          hint: '300 123 4567',
          prefix: _PhonePrefix(),
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: validators.phone,
          onChanged: validators.onChanged,
        ),
        const SizedBox(height: 16),
        RegisterField(
          label: 'Correo electrónico',
          hint: 'Opcional: para recibir novedades',
          icon: Icons.alternate_email_rounded,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          maxLength: FieldLimits.email,
          textInputAction: TextInputAction.next,
          validator: validators.email,
          onChanged: validators.onChanged,
        ),
        const SizedBox(height: 16),
        RegisterField(
          label: 'Contraseña de acceso',
          hint: '••••••••••••',
          icon: Icons.lock_outline_rounded,
          controller: passwordController,
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          maxLength: FieldLimits.passwordMax,
          textInputAction: TextInputAction.done,
          validator: validators.password,
          onChanged: validators.onChanged,
        ),
      ],
    );
  }
}

/// Indicativo `+57` del campo de celular, igual que el que Nest espera.
class _PhonePrefix extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cell_tower, size: 18, color: muted),
          const SizedBox(width: 6),
          Text(
            '+57',
            style: theme.textTheme.labelMedium?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
