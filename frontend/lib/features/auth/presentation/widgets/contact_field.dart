import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/widgets/app_text_field.dart';

class ContactField extends StatelessWidget {
  const ContactField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Correo o celular',
      helperText: 'Usa un correo válido o un celular de 10 dígitos.',
      controller: controller,
      keyboardType: TextInputType.text,
      maxLength: FieldLimits.email,
      textInputAction: TextInputAction.next,
      validator: validator,
      onChanged: onChanged,
    );
  }
}
