import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../data/auth_models.dart';
import '../document_type_labels.dart';
import '../document_type_tabs.dart';

/// Edición del documento: el selector de tipo y su número. Nest exige que
/// los dos campos vayan juntos, así que se editan en el mismo diálogo.
class ProfileDocumentEditor extends StatelessWidget {
  const ProfileDocumentEditor({
    super.key,
    required this.type,
    required this.onTypeChanged,
    required this.numberController,
    required this.validator,
  });

  final DocumentType type;
  final ValueChanged<DocumentType> onTypeChanged;
  final TextEditingController numberController;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de documento',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DocumentTypeTabs(selected: type, onChanged: onTypeChanged),
        const SizedBox(height: 16),
        TextFormField(
          controller: numberController,
          validator: validator,
          keyboardType: DocumentTypeLabels.usesDigits(type)
              ? TextInputType.number
              : TextInputType.text,
          maxLength: FieldLimits.documentNumber,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Número de documento',
            hintText: DocumentTypeLabels.hint(type),
            counterText: '',
          ),
        ),
      ],
    );
  }
}
