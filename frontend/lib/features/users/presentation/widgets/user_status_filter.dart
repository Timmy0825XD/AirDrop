import 'package:flutter/material.dart';

import '../../../../core/widgets/choice_pill.dart';
import '../../../auth/data/auth_models.dart';

/// Filtro de estado de las cuentas en chips: Todas, Activas, Suspendidas.
/// `null` es "Todas" y así lo espera `GET /users?status=`. Las mismas
/// palabras que el filtro de centrales.
class UserStatusFilter extends StatelessWidget {
  const UserStatusFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final UserStatus? selected;
  final ValueChanged<UserStatus?> onChanged;

  static const _options = <(UserStatus?, String)>[
    (null, 'Todas'),
    (UserStatus.active, 'Activas'),
    (UserStatus.suspended, 'Suspendidas'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final (status, label) in _options)
          ChoicePill(
            label: label,
            filled: false,
            selected: status == selected,
            onTap: () => onChanged(status),
          ),
      ],
    );
  }
}
