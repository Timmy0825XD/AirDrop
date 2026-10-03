import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'user_form_values.dart';

/// Datos de la cuenta: nombre, correo, celular opcional y contraseña.
class UserIdentityFields extends StatelessWidget {
  const UserIdentityFields({super.key, required this.values});

  final UserFormValues values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Nombre completo',
          controller: values.name,
          maxLength: FieldLimits.fullName,
          textInputAction: TextInputAction.next,
          validator: Validators.name,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Correo institucional',
          controller: values.email,
          maxLength: FieldLimits.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: Validators.email,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Celular (opcional)',
          controller: values.phone,
          maxLength: FieldLimits.phoneDigits + 2,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          helperText: '10 dígitos. Sin él no llegan alertas por SMS.',
          validator: (value) =>
              (value == null || value.trim().isEmpty)
                  ? null
                  : Validators.phone(value),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Contraseña',
          controller: values.password,
          obscureText: true,
          maxLength: FieldLimits.passwordMax,
          validator: Validators.password,
        ),
      ],
    );
  }
}
