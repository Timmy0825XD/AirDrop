import 'package:flutter/material.dart';

import '../../../auth/data/auth_models.dart';

/// Filtros del listado de cuentas. Dos segmentados apilados: rol (Todos,
/// Despachador, Operador) y estado (Todos, Activa, Suspendida).
///
/// `null` significa "sin filtro" y así lo espera `GET /users?role=&status=`:
/// sin parámetro Nest devuelve los dos roles institucionales. El rol nunca
/// ofrece `requester`: el API no lista solicitantes.
class UserFilterTabs extends StatelessWidget {
  const UserFilterTabs({
    super.key,
    required this.role,
    required this.status,
    required this.onRoleChanged,
    required this.onStatusChanged,
  });

  final UserRole? role;
  final UserStatus? status;
  final ValueChanged<UserRole?> onRoleChanged;
  final ValueChanged<UserStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SegmentedButton<UserRole?>(
          segments: const [
            ButtonSegment(value: null, label: Text('Todos')),
            ButtonSegment(value: UserRole.dispatcher, label: Text('Despachador')),
            ButtonSegment(value: UserRole.fleetOperator, label: Text('Operador')),
          ],
          selected: {role},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => onRoleChanged(selection.first),
        ),
        const SizedBox(height: 8),
        SegmentedButton<UserStatus?>(
          segments: const [
            ButtonSegment(value: null, label: Text('Cualquiera')),
            ButtonSegment(value: UserStatus.active, label: Text('Activa')),
            ButtonSegment(value: UserStatus.suspended, label: Text('Suspendida')),
          ],
          selected: {status},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => onStatusChanged(selection.first),
        ),
      ],
    );
  }
}
