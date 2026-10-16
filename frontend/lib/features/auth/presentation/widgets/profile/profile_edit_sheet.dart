import 'package:flutter/material.dart';

import '../../../data/auth_models.dart';
import '../auth_field.dart';
import 'profile_document_editor.dart';
import 'profile_field_type.dart';

/// Abre la hoja para editar un dato del perfil y devuelve el `PATCH` listo
/// (o `null` si se cierra sin guardar). Valida con los mismos mensajes de
/// Nest y el campo tiembla si hay error.
Future<UpdateProfileRequest?> showProfileEditSheet(
  BuildContext context, {
  required ProfileFieldType type,
  required String initialValue,
  DocumentType? initialDocumentType,
}) {
  return showModalBottomSheet<UpdateProfileRequest>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => ProfileEditSheet(
      type: type,
      initialValue: initialValue,
      initialDocumentType: initialDocumentType,
    ),
  );
}

class ProfileEditSheet extends StatefulWidget {
  const ProfileEditSheet({
    super.key,
    required this.type,
    required this.initialValue,
    this.initialDocumentType,
  });

  final ProfileFieldType type;
  final String initialValue;
  final DocumentType? initialDocumentType;

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  late final _controller = TextEditingController(text: widget.initialValue);
  late DocumentType _documentType =
      widget.initialDocumentType ?? DocumentType.citizenshipId;
  String? _error;
  int _shakeCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final error = widget.type.validate(_controller.text, _documentType);
    setState(() {
      _error = error;
      if (error != null) _shakeCount++;
    });
    if (error != null) return;
    Navigator.of(
      context,
    ).pop(widget.type.request(_controller.text.trim(), _documentType));
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Editar ${type.label.toLowerCase()}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          if (type == ProfileFieldType.document)
            ProfileDocumentEditor(
              type: _documentType,
              onTypeChanged: (value) => setState(() => _documentType = value),
              numberController: _controller,
              errorText: _error,
              shakeCount: _shakeCount,
            )
          else
            AuthField(
              label: type.label,
              hint: type.label,
              controller: _controller,
              keyboardType: type.keyboardType,
              maxLength: type.maxLength,
              errorText: _error,
              shakeCount: _shakeCount,
              onSubmitted: (_) => _save(),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
