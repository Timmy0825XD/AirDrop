import 'package:flutter/material.dart';
import '../../../../core/widgets/auth_field.dart';
import '../../../../core/widgets/drone_glyph.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_icons.dart';
import '../../data/fleet_models.dart';
import 'drone_form/field_row_separator.dart';

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
  final bool coldCompartment;
  final List<DroneModel> models;
  final String? selectedId;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final int shakeCount;
  @override
  Widget build(BuildContext context) {
    final ordered = [...models]
      ..sort((a, b) => a.maxPayloadKg.compareTo(b.maxPayloadKg));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShakeOnError(
          trigger: errorText == null ? 0 : shakeCount,
          child: GlassCard(
            radius: 16,
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  for (final (index, model) in ordered.indexed) ...[
                    if (index > 0) const Divider(height: 1),
                    _ModelOption(
                      model: model,
                      selected: model.id == selectedId,
                      onSelect: () => onChanged(model.id),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        AuthFieldError(message: errorText),
      ],
    );
  }
}

class _ModelOption extends StatelessWidget {
  const _ModelOption({
    required this.model,
    required this.selected,
    required this.onSelect,
  });
  final DroneModel model;
  final bool selected;
  final VoidCallback onSelect;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.06)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: selected
              ? BorderSide(color: colors.primary, width: 1.5)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                DroneGlyph(color: colors.onSurface, size: 25),
                const FieldRowSeparator(),
                Expanded(child: _ModelNames(model: model)),
                const SizedBox(width: 10),
                _ModelSelection(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModelNames extends StatelessWidget {
  const _ModelNames({required this.model});
  final DroneModel model;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(model.name, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 3),
      Text(
        '${_number(model.maxPayloadKg)} kg · ${_number(model.maxRangeKm)} km',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _ModelSelection extends StatelessWidget {
  const _ModelSelection({required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? colors.primary : Colors.transparent,
          border: Border.all(color: selected ? colors.primary : colors.outline),
        ),
        child: selected
            ? Icon(AppIcons.check, size: 14, color: colors.onPrimary)
            : null,
      ),
    );
  }
}

String droneModelSpecs(DroneModel model, {bool coldCompartment = false}) => [
  '${_number(model.maxSpeedKmh)} km/h',
  '${_number(model.payloadKg(coldCompartment: coldCompartment))} kg de carga',
  '${_number(model.maxRangeKm)} km de alcance',
  if (model.ceilingM case final ceiling?)
    'techo ${_number(ceiling)} m s. n. m.',
  if (model.windSustainedMs case final wind?)
    'viento hasta ${_number(wind)} m/s',
].join(' · ');

String _number(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toString();
