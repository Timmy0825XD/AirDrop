import 'package:flutter/material.dart';

import '../../../auth/data/auth_models.dart';
import '../../data/user_models.dart';

/// Selector del rol de la cuenta. Solo ofrece los dos roles
/// institucionales: el solicitante se autoregistra y el admin no se crea
/// a sí mismo por esta vía.
class UserRoleField extends StatelessWidget {
  const UserRoleField({super.key, required this.role, required this.onChanged});

  final UserRole role;
  final ValueChanged<UserRole?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<UserRole>(
      initialValue: role,
      decoration: const InputDecoration(labelText: 'Rol'),
      items: [
        for (final value in institutionalRoles)
          DropdownMenuItem(
            value: value,
            child: Text(switch (value) {
              UserRole.dispatcher => 'Despachador',
              _ => 'Operador de flota',
            }),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
