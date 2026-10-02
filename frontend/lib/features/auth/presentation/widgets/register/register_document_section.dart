import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../data/auth_models.dart';
import '../document_type_labels.dart';
import '../document_type_tabs.dart';
import 'register_field.dart';

/// Bloque "Tipo de documento": el selector y el número. El tipo manda el
/// hint y el patrón de validación, porque una cédula es solo dígitos y el
/// PPT admite letras.
class RegisterDocumentSection extends StatelessWidget {
  const RegisterDocumentSection({
    super.key,
    required this.type,
    required this.onTypeChanged,
    required this.numberController,
    required this.validator,
    required this.onChanged,
  });

  final DocumentType type;
  final ValueChanged<DocumentType> onTypeChanged;
  final TextEditingController numberController;
  final String? Function(String?)? validator;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
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
        RegisterField(
          label: 'Número de documento',
          badge: 'Requerido',
          hint: DocumentTypeLabels.hint(type),
          icon: Icons.badge_outlined,
          controller: numberController,
          keyboardType: DocumentTypeLabels.usesDigits(type)
              ? TextInputType.number
              : TextInputType.text,
          maxLength: FieldLimits.documentNumber,
          textInputAction: TextInputAction.next,
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
