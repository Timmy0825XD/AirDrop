import 'package:flutter/material.dart';

/// El compartimento de frío del dron (RF-49): lo necesitan los insumos
/// refrigerados y pesa 1 kg, que se descuenta de la carga útil.
class ColdCompartmentSwitch extends StatelessWidget {
  const ColdCompartmentSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: value
            ? colors.tertiary.withValues(alpha: 0.10)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      // Material propio: sin él, el fondo teñido taparía la onda al tocar.
      child: Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          secondary: Icon(
            Icons.ac_unit_rounded,
            color: value ? colors.tertiary : colors.onSurfaceVariant,
          ),
          title: Text(
            'Compartimento de frío',
            style: theme.textTheme.titleSmall,
          ),
          subtitle: Text(
            'Para insumos refrigerados. Resta 1 kg de carga útil.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}
