import 'package:flutter/material.dart';

import '../../../data/auth_models.dart';
import 'register_role_tabs.dart';

/// Bloque "Rol operativo aeromédico": etiqueta, pestañas y la nota de
/// correo institucional cuando el rol lo exige.
class RegisterRoleSection extends StatelessWidget {
  const RegisterRoleSection({
    super.key,
    required this.selectedRole,
    required this.onChanged,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rol operativo aeromédico',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        RegisterRoleTabs(selectedRole: selectedRole, onChanged: onChanged),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: selectedRole.requiresEmail
              ? const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: RegisterRoleHint(
                    text: 'Correo institucional obligatorio.',
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}