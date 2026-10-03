import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/validators.dart';
import '../../../../../core/widgets/app_text_field.dart';
import 'hub_form_values.dart';

/// Campos de contacto de la central. El celular se valida con
/// `Validators.phone`, que ya normaliza el prefijo `57`. El correo es
/// opcional en `CreateHubDto`: vacío pasa, pero si viene tiene que ser
/// válido o Nest responde 400.
class HubContactFields extends StatelessWidget {
  const HubContactFields({super.key, required this.values});

  final HubFormValues values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Celular de contacto',
          controller: values.phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: Validators.phone,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Correo de contacto',
          controller: values.email,
          keyboardType: TextInputType.emailAddress,
          maxLength: FieldLimits.email,
          textInputAction: TextInputAction.done,
          validator: _optionalEmail,
        ),
      ],
    );
  }

  static String? _optionalEmail(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : Validators.email(text);
  }
}
