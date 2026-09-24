import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/auth_models.dart';

enum ProfileFieldType { fullName, email, phone }

class ProfileEditDialog extends StatefulWidget {
  const ProfileEditDialog({
    super.key,
    required this.type,
    required this.initialValue,
  });

  final ProfileFieldType type;
  final String initialValue;

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _label => switch (widget.type) {
    ProfileFieldType.fullName => 'Nombre completo',
    ProfileFieldType.email => 'Correo electrónico',
    ProfileFieldType.phone => 'Celular',
  };

  String? _validate(String? value) {
    return switch (widget.type) {
      ProfileFieldType.fullName => Validators.name(value),
      ProfileFieldType.email => Validators.email(value),
      ProfileFieldType.phone => Validators.phone(value),
    };
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final value = _controller.text.trim();
    final request = switch (widget.type) {
      ProfileFieldType.fullName => UpdateProfileRequest(fullName: value),
      ProfileFieldType.email => UpdateProfileRequest(email: value),
      ProfileFieldType.phone => UpdateProfileRequest(phone: value),
    };
    Navigator.of(context).pop(request);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar $_label'),
      content: Form(
        key: _formKey,
        child: AppTextField(
          label: _label,
          controller: _controller,
          keyboardType: switch (widget.type) {
            ProfileFieldType.fullName => TextInputType.name,
            ProfileFieldType.email => TextInputType.emailAddress,
            ProfileFieldType.phone => TextInputType.phone,
          },
          maxLength: switch (widget.type) {
            ProfileFieldType.fullName => FieldLimits.fullName,
            ProfileFieldType.email => FieldLimits.email,
            ProfileFieldType.phone => null,
          },
          textInputAction: TextInputAction.done,
          validator: _validate,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
