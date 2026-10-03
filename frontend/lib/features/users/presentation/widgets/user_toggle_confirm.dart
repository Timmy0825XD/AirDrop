import 'package:flutter/material.dart';

import '../../../auth/data/auth_models.dart';

/// Confirma la suspensión o la reactivación de una cuenta.
///
/// Suspender bloquea el acceso del despachador u operador al instante, así
/// que pide confirmación. Devuelve `true` solo si el administrador lo
/// confirma.
Future<bool> confirmUserSuspension(
  BuildContext context, {
  required PublicUser user,
}) async {
  final suspend = user.status == UserStatus.active;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(suspend ? 'Suspender cuenta' : 'Reactivar cuenta'),
      content: Text(
        suspend
            ? '¿Quieres suspender la cuenta de ${user.fullName}? Perderá el '
                'acceso hasta que la reactives.'
            : '¿Quieres reactivar la cuenta de ${user.fullName}?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(suspend ? 'Suspender' : 'Reactivar'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
