import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import 'register_field.dart';
import 'register_field_validators.dart';

/// El primer campo del registro: nombre completo con su validador y el
/// badge de "Requerido". Vive aparte para que `RegisterFields` solo ordene
/// los bloques del formulario.
class RegisterNameField extends StatelessWidget {
  const RegisterNameField({
    super.key,
    required this.controller,
    required this.validators,
  });

  final TextEditingController controller;
  final RegisterFieldValidators validators;

  @override
  Widget build(BuildContext context) {
    return RegisterField(
      label: 'Nombre completo',
      badge: 'Requerido',
      hint: 'Valentina Morales',
      icon: Icons.person_outline_rounded,
      controller: controller,
      maxLength: FieldLimits.fullName,
      textInputAction: TextInputAction.next,
      validator: validators.name,
      onChanged: validators.onChanged,
    );
  }
}
