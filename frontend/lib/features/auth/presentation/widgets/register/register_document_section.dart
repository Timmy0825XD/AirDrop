import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../data/auth_models.dart';
import '../auth_field.dart';
import '../document_type_labels.dart';
import '../document_type_tabs.dart';
import 'register_fields.dart';

/// Nombre, tipo de documento y número. El tipo manda el ejemplo, la nota y
/// el teclado del número, porque una cédula es solo dígitos y el PPT
/// admite letras.
class RegisterIdentityFields extends StatelessWidget {
  const RegisterIdentityFields({
    super.key,
    required this.data,
    required this.documentType,
    required this.onDocumentTypeChanged,
  });

  final RegisterFormData data;
  final DocumentType documentType;
  final ValueChanged<DocumentType> onDocumentTypeChanged;

  @override
  Widget build(BuildContext context) {
    final c = data.controllers;
    final digits = DocumentTypeLabels.usesDigits(documentType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthField(
          label: 'Nombre completo',
          hint: 'Como aparece en tu documento',
          icon: Icons.person_outline_rounded,
          controller: c.name,
          errorText: data.errors[RegisterInput.name],
          shakeCount: data.shakeCount,
          maxLength: FieldLimits.fullName,
          autofillHints: const [AutofillHints.name],
          onChanged: data.onChanged,
        ),
        const SizedBox(height: 18),
        Text(
          'TIPO DE DOCUMENTO',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        DocumentTypeTabs(
          selected: documentType,
          onChanged: onDocumentTypeChanged,
        ),
        const SizedBox(height: 18),
        AuthField(
          label: 'Número de documento',
          hint: DocumentTypeLabels.hint(documentType),
          icon: Icons.badge_outlined,
          trailing: AuthFieldNote(DocumentTypeLabels.lengthNote(documentType)),
          controller: c.document,
          errorText: data.errors[RegisterInput.document],
          shakeCount: data.shakeCount,
          keyboardType: digits ? TextInputType.number : TextInputType.text,
          maxLength: FieldLimits.documentNumber,
          onChanged: data.onChanged,
        ),
      ],
    );
  }
}
