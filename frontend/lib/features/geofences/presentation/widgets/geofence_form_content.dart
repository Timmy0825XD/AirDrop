import 'package:flutter/material.dart';

import '../../../../core/widgets/primary_button.dart';
import '../../data/geofence_models.dart';
import 'geofence_fields.dart';
import 'geofence_form_values.dart';
import 'polygon_point_fields.dart';

/// Cuerpo del formulario de geovallas: nombre, motivo, vértices y
/// botón. La pantalla conserva el estado de carga y el envío.
class GeofenceFormContent extends StatelessWidget {
  const GeofenceFormContent({
    super.key,
    required this.formKey,
    required this.values,
    required this.onSubmit,
    required this.onVerticesChanged,
    required this.isLoading,
    this.original,
  });

  final GlobalKey<FormState> formKey;
  final GeofenceFormValues values;
  final VoidCallback onSubmit;
  final VoidCallback onVerticesChanged;
  final bool isLoading;

  /// `null` en el alta; con geovalla existente el botón dice
  /// "Guardar cambios".
  final Geofence? original;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GeofenceFields(values: values),
            const SizedBox(height: 16),
            PolygonPointFields(values: values, onChanged: onVerticesChanged),
            const SizedBox(height: 24),
            PrimaryButton(
              label: original == null ? 'Crear geovalla' : 'Guardar cambios',
              isLoading: isLoading,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
