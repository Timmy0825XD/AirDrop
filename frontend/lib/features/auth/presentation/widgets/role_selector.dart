import 'package:flutter/material.dart';

import '../../data/auth_models.dart';

class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onChanged,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  static const _roles = [
    UserRole.requester,
    UserRole.dispatcher,
    UserRole.fleetOperator,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final role in _roles)
          ChoiceChip(
            label: Text(_label(role)),
            selected: role == selectedRole,
            onSelected: (_) => onChanged(role),
            labelStyle: theme.textTheme.labelLarge,
          ),
      ],
    );
  }

  String _label(UserRole role) {
    return switch (role) {
      UserRole.requester => 'Solicitante',
      UserRole.dispatcher => 'Despachador',
      UserRole.fleetOperator => 'Operador de flota',
      UserRole.admin => 'Administrador',
    };
  }
}
