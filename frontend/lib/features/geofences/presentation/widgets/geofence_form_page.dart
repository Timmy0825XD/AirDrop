import 'package:flutter/material.dart';

import '../../../../core/widgets/compact_form_header.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../core/widgets/form_submit_button.dart';
import 'geofence_form_sheet.dart';
import 'geofence_form_values.dart';

class GeofenceFormPage extends StatelessWidget {
  const GeofenceFormPage({
    super.key,
    required this.values,
    required this.errors,
    required this.shakeCount,
    required this.loading,
    required this.isEdit,
    required this.onChanged,
    required this.onBack,
    required this.onSubmit,
  });
  final GeofenceFormValues values;
  final Map<GeofenceInput, String> errors;
  final int shakeCount;
  final bool loading, isEdit;
  final VoidCallback onChanged, onBack, onSubmit;
  @override
  Widget build(BuildContext context) {
    final title = isEdit ? 'Editar geovalla' : 'Nueva geovalla';
    return ContentPage(
      title: title,
      subtitle: 'Zona operativa',
      onBack: onBack,
      header: CompactFormHeader(
        title: title,
        subtitle: 'Zona operativa',
        onBack: onBack,
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IgnorePointer(
                ignoring: loading,
                child: GeofenceFormSheet(
                  values: values,
                  errors: errors,
                  shakeCount: shakeCount,
                  onChanged: onChanged,
                  isEdit: isEdit,
                ),
              ),
              const SizedBox(height: 28),
              _GeofenceSubmitButton(
                isEdit: isEdit,
                loading: loading,
                onSubmit: onSubmit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GeofenceSubmitButton extends StatelessWidget {
  const _GeofenceSubmitButton({
    required this.isEdit,
    required this.loading,
    required this.onSubmit,
  });
  final bool isEdit, loading;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) => FormSubmitButton(
    label: isEdit ? 'Guardar cambios' : 'Crear geovalla',
    loadingLabel: 'Guardando geovalla',
    loading: loading,
    onPressed: onSubmit,
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
