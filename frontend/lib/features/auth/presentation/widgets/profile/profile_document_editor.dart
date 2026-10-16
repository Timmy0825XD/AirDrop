import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../data/auth_models.dart';
import '../auth_field.dart';
import '../document_type_labels.dart';
import '../document_type_tabs.dart';

/// Edición del documento: el selector de tipo y su número. Nest exige que
/// los dos campos vayan juntos, así que se editan en la misma hoja.
class ProfileDocumentEditor extends StatelessWidget {
  const ProfileDocumentEditor({
    super.key,
    required this.type,
    required this.onTypeChanged,
    required this.numberController,
    this.errorText,
    this.shakeCount = 0,
  });

  final DocumentType type;
  final ValueChanged<DocumentType> onTypeChanged;
  final TextEditingController numberController;
  final String? errorText;
  final int shakeCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'TIPO DE DOCUMENTO',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        DocumentTypeTabs(selected: type, onChanged: onTypeChanged),
        const SizedBox(height: 16),
        AuthField(
          label: 'Número de documento',
          hint: DocumentTypeLabels.hint(type),
          controller: numberController,
          keyboardType: DocumentTypeLabels.usesDigits(type)
              ? TextInputType.number
              : TextInputType.text,
          maxLength: FieldLimits.documentNumber,
          errorText: errorText,
          shakeCount: shakeCount,
        ),
      ],
    );
  }
}
