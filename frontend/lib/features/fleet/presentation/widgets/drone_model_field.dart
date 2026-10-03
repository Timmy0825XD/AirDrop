import 'package:flutter/material.dart';

import '../../data/fleet_models.dart';

/// Selector del modelo de dron. Muestra el `name` de `GET /fleet/models`
/// y devuelve el `id`, que es lo que Nest espera en `droneModelId`.
///
/// Debajo pinta las especificaciones del modelo elegido; con un solo
/// modelo sembrado (Wingcopter 198) igual sirve para que el operador vea
/// velocidad, carga y alcance antes de dar de alta el dron.
class DroneModelField extends StatelessWidget {
  const DroneModelField({
    super.key,
    required this.models,
    required this.selectedId,
    required this.onChanged,
    this.errorText,
  });

  final List<DroneModel> models;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final known = models.any((model) => model.id == selectedId);
    final selected = known ? _find(models, selectedId!) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'MODELO DE DRON',
          style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: known ? selectedId : null,
          items: [
            for (final model in models)
              DropdownMenuItem(value: model.id, child: Text(model.name)),
          ],
          onChanged: onChanged,
        ),
        if (selected != null) ...[
          const SizedBox(height: 8),
          _ModelSpecs(model: selected),
        ],
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

/// Velocidad, carga y alcance del modelo elegido.
class _ModelSpecs extends StatelessWidget {
  const _ModelSpecs({required this.model});

  final DroneModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '${_number(model.maxSpeedKmh)} km/h · '
      '${_number(model.maxPayloadKg)} kg de carga · '
      '${_number(model.maxRangeKm)} km de alcance',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }
}

DroneModel? _find(List<DroneModel> models, String id) {
  for (final model in models) {
    if (model.id == id) return model;
  }
  return null;
}

/// Postgres `numeric` llega como `150.0`; en pantalla se ve `150`.
String _number(double value) {
  return value == value.roundToDouble()
      ? value.round().toString()
      : value.toString();
}
