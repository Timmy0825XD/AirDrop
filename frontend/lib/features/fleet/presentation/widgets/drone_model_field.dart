import 'package:flutter/material.dart';

import '../../../../core/widgets/choice_pill.dart';
import '../../../auth/presentation/widgets/auth_choice_group.dart';
import '../../data/fleet_models.dart';

/// El tipo de dron en chips: Colibrí, Garza o Cóndor (RF-49). Muestra el
/// `name` de `GET /fleet/models` y devuelve el `id`, que es lo que Nest
/// espera en `droneModelId`. Debajo, velocidad, carga, alcance, techo y
/// viento del elegido; la carga ya descuenta el compartimento de frío.
class DroneModelField extends StatelessWidget {
  const DroneModelField({
    super.key,
    required this.models,
    required this.selectedId,
    required this.onChanged,
    this.coldCompartment = false,
    this.errorText,
    this.shakeCount = 0,
  });

  /// Con el compartimento de frío la carga útil baja 1 kg.
  final bool coldCompartment;
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
          label: 'Tipo de dron',
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
              : _ModelSpecs(model: selected, cold: coldCompartment),
        ),
      ],
    );
  }
}

/// "110 km/h · 4 kg de carga · 90 km de alcance", y si Nest los manda, el
/// techo y el viento que aguanta.
String droneModelSpecs(DroneModel model, {bool coldCompartment = false}) => [
  '${_number(model.maxSpeedKmh)} km/h',
  '${_number(model.payloadKg(coldCompartment: coldCompartment))} kg de carga',
  '${_number(model.maxRangeKm)} km de alcance',
  if (model.ceilingM case final ceiling?)
    'techo ${_number(ceiling)} m s. n. m.',
  if (model.windSustainedMs case final wind?)
    'viento hasta ${_number(wind)} m/s',
].join(' · ');

/// Las cifras del tipo elegido.
class _ModelSpecs extends StatelessWidget {
  const _ModelSpecs({required this.model, required this.cold});

  final DroneModel model;
  final bool cold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        droneModelSpecs(model, coldCompartment: cold),
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
