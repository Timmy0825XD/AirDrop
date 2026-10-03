import 'package:flutter/material.dart';

/// Marca de cadena de frío del ítem. El insumo refrigerado viaja con
/// monitoreo de temperatura y, si hay alerta, no vuelve a dispensarse
/// ([`context/entregas/productos.md`]).
class InventoryColdChainSwitch extends StatelessWidget {
  const InventoryColdChainSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: const Text('Cadena de frío'),
        subtitle: Text(
          'Viaja con monitoreo de temperatura.',
          style: theme.textTheme.bodySmall,
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
