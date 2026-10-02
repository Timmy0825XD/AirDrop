import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/validators.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../data/auth_models.dart';
import '../document_type_labels.dart';
import 'profile_document_editor.dart';

enum ProfileFieldType { fullName, email, phone, document }

class ProfileEditDialog extends StatefulWidget {
  const ProfileEditDialog({
    super.key,
    required this.type,
    required this.initialValue,
    this.initialDocumentType,
  });

  final ProfileFieldType type;
  final String initialValue;

  /// Solo aplica al documento: las cuentas institucionales no lo tienen.
  final DocumentType? initialDocumentType;

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late DocumentType _documentType;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _documentType = widget.initialDocumentType ?? DocumentType.citizenshipId;
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
    ProfileFieldType.document => 'Documento',
  };

  String? _validate(String? value) {
    return switch (widget.type) {
      ProfileFieldType.fullName => Validators.name(value),
      ProfileFieldType.email => Validators.email(value),
      ProfileFieldType.phone => Validators.phone(value),
      ProfileFieldType.document =>
        DocumentTypeLabels.usesDigits(_documentType)
            ? Validators.documentDigits(value)
            : Validators.documentPpt(value),
    };
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final value = _controller.text.trim();
    final request = switch (widget.type) {
      ProfileFieldType.fullName => UpdateProfileRequest(fullName: value),
      ProfileFieldType.email => UpdateProfileRequest(email: value),
      ProfileFieldType.phone => UpdateProfileRequest(phone: value),
      // El tipo y el número se mandan siempre juntos.
      ProfileFieldType.document => UpdateProfileRequest(
        documentType: _documentType,
        documentNumber: value,
      ),
    };
    Navigator.of(context).pop(request);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar $_label'),
      content: Form(key: _formKey, child: _content()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }

  Widget _content() {
    if (widget.type == ProfileFieldType.document) {
      return ProfileDocumentEditor(
        type: _documentType,
        onTypeChanged: (type) => setState(() => _documentType = type),
        numberController: _controller,
        validator: _validate,
      );
    }
    return AppTextField(
      label: _label,
      controller: _controller,
      keyboardType: switch (widget.type) {
        ProfileFieldType.fullName => TextInputType.name,
        ProfileFieldType.email => TextInputType.emailAddress,
        _ => TextInputType.phone,
      },
      maxLength: switch (widget.type) {
        ProfileFieldType.fullName => FieldLimits.fullName,
        ProfileFieldType.email => FieldLimits.email,
        _ => null,
      },
      textInputAction: TextInputAction.done,
      validator: _validate,
    );
  }
}
