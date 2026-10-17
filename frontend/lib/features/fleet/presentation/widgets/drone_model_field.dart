import 'package:flutter/material.dart';

import '../../../../core/widgets/choice_pill.dart';
import '../../../auth/presentation/widgets/auth_choice_group.dart';
import '../../data/fleet_models.dart';

/// El modelo de dron en chips (muestra el `name` de `GET /fleet/models` y
/// devuelve el `id`, que es lo que Nest espera en `droneModelId`). Debajo,
/// velocidad, carga y alcance del elegido; con un solo modelo sembrado
/// (Wingcopter 198) igual le sirve al operador para verlo.
class DroneModelField extends StatelessWidget {
  const DroneModelField({
    super.key,
    required this.models,
    required this.selectedId,
    required this.onChanged,
    this.errorText,
    this.shakeCount = 0,
  });

  final List<DroneModel> models;
  final String? selectedId;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final int shakeCount;

  @override
  Widget build(BuildContext context) {
    final selected = models.where((m) => m.id == selectedId).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthChoiceGroup(
          label: 'Modelo de dron',
          errorText: errorText,
          shakeCount: shakeCount,
          children: [
            for (final model in models)
              ChoicePill(
                label: model.name,
                selected: model.id == selectedId,
                onTap: () => onChanged(model.id),
              ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.fastOutSlowIn,
          child: selected == null
              ? const SizedBox(width: double.infinity)
              : _ModelSpecs(model: selected),
        ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '${_number(model.maxSpeedKmh)} km/h · '
        '${_number(model.maxPayloadKg)} kg de carga · '
        '${_number(model.maxRangeKm)} km de alcance',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Postgres `numeric` llega como `150.0`; en pantalla se ve `150`.
String _number(double value) {
  return value == value.roundToDouble()
      ? value.round().toString()
      : value.toString();
}
