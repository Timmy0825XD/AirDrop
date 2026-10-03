import 'package:flutter/material.dart';

import '../login/login_button.dart';
import 'register_contact_fields.dart';
import 'register_consent_row.dart';
import 'register_field_validators.dart';
import 'register_name_field.dart';

export 'register_field_validators.dart';

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

  /// Los arma la pantalla: el tipo de documento elegido decide el validador.
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
        RegisterNameField(controller: nameController, validators: validators),
        const SizedBox(height: 16),
        documentSection,
        const SizedBox(height: 16),
        RegisterContactFields(
          phoneController: phoneController,
          emailController: emailController,
          passwordController: passwordController,
          validators: validators,
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
}
