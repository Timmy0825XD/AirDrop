import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../login/login_button.dart';
import 'register_consent_row.dart';
import 'register_field.dart';

/// Los campos del formulario de registro, en el orden en que aparecen.
/// Solo arma la lista de widgets; la validación vive en la pantalla.
class RegisterFields extends StatelessWidget {
  const RegisterFields({
    super.key,
    required this.nameController,
    required this.documentNumberController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.documentSection,
    required this.consentAccepted,
    required this.onConsentChanged,
    required this.onSubmit,
    required this.validators,
    this.isLoading = false,
  });

  final TextEditingController nameController;
  final TextEditingController documentNumberController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  /// El selector de tipo y su campo los arma la pantalla, porque el tipo
  /// elegido decide el validador del número y ella tiene el estado.
  final Widget documentSection;

  final bool consentAccepted;
  final ValueChanged<bool> onConsentChanged;
  final VoidCallback onSubmit;
  final RegisterFieldValidators validators;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegisterField(
          label: 'Nombre completo',
          badge: 'Requerido',
          hint: 'Valentina Morales',
          icon: Icons.person_outline_rounded,
          controller: nameController,
          maxLength: FieldLimits.fullName,
          textInputAction: TextInputAction.next,
          validator: validators.name,
          onChanged: validators.onChanged,
        ),
        const SizedBox(height: 16),
        documentSection,
        const SizedBox(height: 16),
        RegisterField(
          label: 'Celular de contacto',
          hint: '300 123 4567',
          prefix: _phonePrefix(context),
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
        const SizedBox(height: 18),
        RegisterConsentRow(value: consentAccepted, onChanged: onConsentChanged),
        const SizedBox(height: 18),
        LoginButton(
          label: 'Crear cuenta',
          icon: Icons.how_to_reg_outlined,
          iconFirst: true,
          isLoading: isLoading,
          onPressed: onSubmit,
        ),
      ],
    );
  }

  Widget _phonePrefix(BuildContext context) {
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

/// Agrupa los validadores y el callback de limpieza de error, para que
/// la pantalla no los pase uno por uno en cada campo.
class RegisterFieldValidators {
  const RegisterFieldValidators({
    required this.name,
    required this.documentNumber,
    required this.phone,
    required this.email,
    required this.password,
    required this.onChanged,
  });

  final String? Function(String?)? name;
  final String? Function(String?)? documentNumber;
  final String? Function(String?)? phone;
  final String? Function(String?)? email;
  final String? Function(String?)? password;
  final ValueChanged<String> onChanged;
}
