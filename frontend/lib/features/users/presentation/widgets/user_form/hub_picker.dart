import 'package:flutter/material.dart';

import '../../../../../core/widgets/choice_pill.dart';
import '../../../../auth/data/auth_models.dart';
import '../../../../auth/presentation/widgets/auth_field.dart';
import '../../../../hubs/data/hub_models.dart';

/// Las centrales activas como chips: el despachador elige una, el
/// operador una o varias. Sin centrales activas no hay a quién asignar la
/// cuenta, así que se dice y se ofrece crear una.
class HubPicker extends StatelessWidget {
  const HubPicker({
    super.key,
    required this.role,
    required this.hubs,
    required this.selectedIds,
    required this.onToggle,
    required this.onCreateHub,
    this.errorText,
  });

  final UserRole role;
  final List<Hub> hubs;
  final List<String> selectedIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onCreateHub;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PickerHeader(role: role),
        const SizedBox(height: 8),
        if (hubs.isEmpty)
          _NoHubs(onCreateHub: onCreateHub)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final hub in hubs)
                ChoicePill(
                  label: hub.name,
                  showCheck: true,
                  selected: selectedIds.contains(hub.id),
                  onTap: () => onToggle(hub.id),
                ),
            ],
          ),
        AuthFieldError(message: errorText),
      ],
    );
  }
}

/// "CENTRALES" y la regla del rol a la derecha.
class _PickerHeader extends StatelessWidget {
  const _PickerHeader({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text('CENTRALES', style: theme.textTheme.labelSmall)),
        Text(
          role == UserRole.dispatcher ? 'Elige una' : 'Elige una o varias',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NoHubs extends StatelessWidget {
  const _NoHubs({required this.onCreateHub});

  final VoidCallback onCreateHub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'No hay centrales activas. Crea una antes de crear cuentas.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: onCreateHub,
            child: const Text('Crear central'),
          ),
        ],
      ),
    );
  }
}
