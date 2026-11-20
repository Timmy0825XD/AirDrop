import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api_exception.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../data/geofence_models.dart';
import '../../data/geofence_providers.dart';
import 'reason_prompt.dart';

/// RU-36: lo que el admin hace con una zona legal desde su ficha: editarla
/// o desactivarla / reactivarla, siempre con motivo. No hay "Eliminar".
class LegalZoneActions extends ConsumerWidget {
  const LegalZoneActions({super.key, required this.zone});

  final Geofence zone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/geofences/${zone.id}');
          },
          icon: const Icon(Icons.edit_rounded),
          label: const Text('Editar'),
        ),
        const SizedBox(width: 12),
        TextButton.icon(
          onPressed: () => _toggle(context, ref),
          icon: Icon(zone.active ? Icons.block_rounded : Icons.check_rounded),
          label: Text(zone.active ? 'Desactivar' : 'Reactivar'),
        ),
      ],
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final active = !zone.active;
    final reason = await showReasonPrompt(
      context,
      title: active ? 'Reactivar la zona' : 'Desactivar la zona',
      confirmLabel: active ? 'Reactivar' : 'Desactivar',
    );
    if (reason == null || !context.mounted) return;
    try {
      await ref
          .read(legalZoneAdminProvider.notifier)
          .setActive(zone.id, active: active, reason: reason);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      showAppSnack(context, active ? 'Zona reactivada.' : 'Zona desactivada.');
    } on ApiException catch (error) {
      if (context.mounted) showErrorSnack(context, error.message);
    }
  }
}
