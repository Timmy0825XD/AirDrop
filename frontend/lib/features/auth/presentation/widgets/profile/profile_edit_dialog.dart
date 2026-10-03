import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_text_field.dart';
import '../../../data/auth_models.dart';
import 'profile_document_editor.dart';
import 'profile_field_type.dart';

export 'profile_field_type.dart';

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

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final value = _controller.text.trim();
    Navigator.of(context).pop(widget.type.request(value, _documentType));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar ${widget.type.label}'),
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
    final type = widget.type;
    if (type == ProfileFieldType.document) {
      return ProfileDocumentEditor(
        type: _documentType,
        onTypeChanged: (value) => setState(() => _documentType = value),
        numberController: _controller,
        validator: (value) => type.validate(value, _documentType),
      );
    }
    return AppTextField(
      label: type.label,
      controller: _controller,
      keyboardType: type.keyboardType,
      maxLength: type.maxLength,
      textInputAction: TextInputAction.done,
      validator: (value) => type.validate(value, _documentType),
    );
  }
}
