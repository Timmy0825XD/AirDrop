import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../hubs/data/hub_models.dart';
import '../../../hubs/presentation/widgets/hub_status_chip.dart';
import '../../data/fleet_models.dart';
import 'drone_form_values.dart';
import 'drone_model_field.dart';

/// Cuerpo del alta de dron: central destino, identificador, modelo y
/// botón. La pantalla conserva el estado de carga, los avisos y el envío.
///
/// Con la central suspendida el formulario se queda visible pero el botón
/// se apaga: es la "alta deshabilitada" del plan, con el mismo mensaje que
/// devolvería Nest.
class DroneFormContent extends StatelessWidget {
  const DroneFormContent({
    super.key,
    required this.formKey,
    required this.values,
    required this.models,
    required this.hub,
    required this.modelError,
    required this.onModelChanged,
    required this.onSubmit,
    required this.isLoading,
  });

  final GlobalKey<FormState> formKey;
  final DroneFormValues values;
  final List<DroneModel> models;
  final Hub hub;
  final String? modelError;
  final ValueChanged<String?> onModelChanged;
  final VoidCallback onSubmit;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HubSummary(hub: hub),
            const SizedBox(height: 16),
            _IdentifierField(values: values),
            const SizedBox(height: 16),
            DroneModelField(
              models: models,
              selectedId: values.droneModelId,
              onChanged: onModelChanged,
              errorText: modelError,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Agregar dron',
              isLoading: isLoading,
              onPressed: hub.isActive ? onSubmit : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Identificador del dron: máximo 32, el mismo tope que
/// `FIELD_LIMITS.droneIdentifier` de Nest.
class _IdentifierField extends StatelessWidget {
  const _IdentifierField({required this.values});

  final DroneFormValues values;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Identificador',
      controller: values.identifier,
      maxLength: FieldLimits.droneIdentifier,
      helperText: 'Máximo ${FieldLimits.droneIdentifier} caracteres',
      textInputAction: TextInputAction.next,
      validator: Validators.droneIdentifier,
    );
  }
}

/// En qué central va a parar el dron, que es el `hubId` que viaja en el
/// body y que el usuario no escribe.
class _HubSummary extends StatelessWidget {
  const _HubSummary({required this.hub});

  final Hub hub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CENTRAL DESTINO',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(hub.name, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            HubStatusChip(status: hub.status),
          ],
        ),
      ),
    );
  }
}
