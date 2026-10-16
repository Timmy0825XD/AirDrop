import 'package:flutter/material.dart';

import '../../../../core/widgets/status_pill.dart';

import '../../data/hub_models.dart';
import 'hub_detail_row.dart';
import 'hub_labels.dart';

/// Contenido de solo lectura de una central. Sin acciones: el despachador
/// consulta su central, no la administra.
class HubDetailContent extends StatelessWidget {
  const HubDetailContent({super.key, required this.hub});

  final Hub hub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(hub.name, style: theme.textTheme.headlineSmall),
            ),
            StatusPill(
              label: HubLabels.status(hub.status),
              tone: HubLabels.tone(hub.status),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          HubLabels.type(hub.type),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HubDetailRow(label: 'Dirección', value: hub.address),
                HubDetailRow(
                  label: 'Celular de contacto',
                  value: hub.contactPhone,
                ),
                HubDetailRow(
                  label: 'Correo de contacto',
                  value: hub.contactEmail ?? 'Sin correo registrado',
                ),
                HubDetailRow(
                  label: 'Estado',
                  value: HubLabels.status(hub.status),
                ),
                HubDetailRow(label: 'Latitud', value: hub.latitude.toString()),
                HubDetailRow(
                  label: 'Longitud',
                  value: hub.longitude.toString(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
