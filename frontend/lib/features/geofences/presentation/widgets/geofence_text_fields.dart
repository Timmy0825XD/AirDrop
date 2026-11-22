import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/widgets/auth_field.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_icons.dart';
import 'geofence_form_values.dart';

class GeofenceTextFields extends StatelessWidget {
  const GeofenceTextFields({
    super.key,
    required this.values,
    required this.errors,
    required this.shakeCount,
  });
  final GeofenceFormValues values;
  final Map<GeofenceInput, String> errors;
  final int shakeCount;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Datos de la zona', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      GlassCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _GeofenceTextRow(
              label: 'Nombre',
              hint: 'Ej.: Obra del puente',
              controller: values.name,
              icon: AppIcons.tag,
              maxLength: FieldLimits.geofenceName,
              error: errors[GeofenceInput.name],
              shakeCount: shakeCount,
            ),
            const Divider(height: 1),
            _GeofenceTextRow(
              label: 'Motivo',
              hint: 'Describe la restricción',
              controller: values.reason,
              icon: AppIcons.document,
              maxLength: FieldLimits.reason,
              error: errors[GeofenceInput.reason],
              shakeCount: shakeCount,
              multiline: true,
            ),
          ],
        ),
      ),
    ],
  );
}

class _GeofenceTextRow extends StatelessWidget {
  const _GeofenceTextRow({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    required this.maxLength,
    required this.shakeCount,
    this.error,
    this.multiline = false,
  });
  final String label, hint;
  final TextEditingController controller;
  final IconData icon;
  final int maxLength, shakeCount;
  final String? error;
  final bool multiline;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShakeOnError(
          trigger: error == null ? 0 : shakeCount,
          child: Row(
            children: [
              Icon(icon, size: 25),
              SizedBox(
                height: 36,
                child: VerticalDivider(
                  width: 28,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              Expanded(child: _GeofenceTextInput(field: this)),
            ],
          ),
        ),
        AuthFieldError(message: error),
      ],
    ),
  );
}

class _GeofenceTextInput extends StatelessWidget {
  const _GeofenceTextInput({required this.field});
  final _GeofenceTextRow field;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(
        child: Text(field.label, style: Theme.of(context).textTheme.labelLarge),
      ),
      Semantics(
        label: field.label,
        child: TextField(
          controller: field.controller,
          maxLength: field.maxLength,
          maxLines: field.multiline ? 3 : 1,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: field.multiline
              ? TextInputAction.newline
              : TextInputAction.next,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: field.hint,
            counterText: '',
            isDense: true,
            filled: false,
            contentPadding: const EdgeInsets.only(top: 4),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    ],
  );
}
