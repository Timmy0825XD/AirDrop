import 'package:flutter/material.dart';

import '../../../../core/widgets/confirm_sheet.dart';
import '../../data/hub_models.dart';
import 'hub_labels.dart';
import 'hub_tile.dart';

/// Confirma la suspensión o la reactivación de una central en la hoja de
/// abajo. Suspender bloquea en el momento el inventario y la flota de esa
/// central, por eso se pregunta. Devuelve `true` solo si se confirma.
Future<bool> confirmHubSuspension(BuildContext context, {required Hub hub}) {
  final suspend = hub.isActive;
  return showConfirmSheet(
    context,
    title: suspend ? '¿Suspender ${hub.name}?' : '¿Reactivar ${hub.name}?',
    message: suspend
        ? 'Su inventario y su flota quedan bloqueados hasta que la reactives.'
        : 'Vuelve a operar con su inventario y su flota.',
    confirmLabel: suspend ? 'Suspender' : 'Reactivar',
    icon: suspend
        ? Icons.pause_circle_outline_rounded
        : Icons.play_circle_outline_rounded,
    destructive: suspend,
    subject: _HubSubject(hub: hub),
  );
}

class _HubSubject extends StatelessWidget {
  const _HubSubject({required this.hub});

  final Hub hub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          HubTypeTile(hub: hub),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hub.name, style: theme.textTheme.titleSmall),
                Text(
                  '${HubLabels.type(hub.type)} · ${hub.address}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
