import 'package:flutter/material.dart';

import '../../../auth/data/auth_models.dart';
import '../../../hubs/data/hub_models.dart';

/// Selector de centrales según el rol (paso d del plan).
///
/// - Despachador: un **solo** `Dropdown` de centrales `active` →
///   `hubIds: [id]`, porque Nest exige exactamente una.
/// - Operador de flota: selección múltiple con chips, mínimo una.
///
/// El texto de error lo pinta la pantalla; este widget no valida.
class HubMultiSelect extends StatelessWidget {
  const HubMultiSelect({
    super.key,
    required this.role,
    required this.hubs,
    required this.selectedIds,
    required this.onChanged,
    this.errorText,
  });

  final UserRole role;
  final List<Hub> hubs;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final String? errorText;

  bool get _isDispatcher => role == UserRole.dispatcher;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'CENTRALES ASIGNADAS',
          style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        if (_isDispatcher) _SingleHubDropdown(hubs: hubs, selectedIds: selectedIds, onChanged: onChanged)
        else _HubChips(hubs: hubs, selectedIds: selectedIds, onChanged: onChanged),
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

class _SingleHubDropdown extends StatelessWidget {
  const _SingleHubDropdown({
    required this.hubs,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<Hub> hubs;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = selectedIds.isEmpty ? null : selectedIds.first;
    return DropdownButtonFormField<String>(
      initialValue: hubs.any((hub) => hub.id == current) ? current : null,
      decoration: const InputDecoration(helperText: 'El despachador trabaja en una sola central.'),
      items: [
        for (final hub in hubs)
          DropdownMenuItem(value: hub.id, child: Text(hub.name)),
      ],
      onChanged: (id) => onChanged(id == null ? const [] : [id]),
    );
  }
}

class _HubChips extends StatelessWidget {
  const _HubChips({
    required this.hubs,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<Hub> hubs;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final hub in hubs)
          FilterChip(
            label: Text(hub.name),
            selected: selectedIds.contains(hub.id),
            onSelected: (selected) {
              final next = [...selectedIds];
              selected ? next.add(hub.id) : next.remove(hub.id);
              onChanged(next);
            },
          ),
      ],
    );
  }
}
