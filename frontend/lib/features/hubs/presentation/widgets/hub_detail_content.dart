import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/app_map.dart';
import '../../../../core/widgets/detail_section.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/hub_models.dart';
import 'hub_labels.dart';
import 'hub_tile.dart';
import '../../../../theme/app_palette.dart';

/// "Mi central" en solo lectura: quién es, dónde queda en el mapa y cómo
/// contactarla. Sin acciones: el despachador consulta su central, no la
/// administra. Los bloques entran en cascada.
class HubDetailContent extends StatelessWidget {
  const HubDetailContent({super.key, required this.hub});

  final Hub hub;

  @override
  Widget build(BuildContext context) {
    final blocks = [
      _HubIdentity(hub: hub),
      _HubMap(point: LatLng(hub.latitude, hub.longitude)),
      DetailSection(
        title: 'Contacto',
        icon: Icons.call_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DetailLine(label: 'Dirección', value: hub.address),
            DetailLine(label: 'Celular', value: hub.contactPhone),
            DetailLine(
              label: 'Correo',
              value: hub.contactEmail ?? 'Sin correo registrado',
            ),
            DetailLine(
              label: 'Coordenadas',
              value:
                  '${hub.latitude.toStringAsFixed(6)}, '
                  '${hub.longitude.toStringAsFixed(6)}',
            ),
          ],
        ),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, block) in blocks.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RiseIn(delay: RiseIn.stagger(i), child: block),
          ),
      ],
    );
  }
}

/// El ícono del tipo, el nombre, el tipo y el estado.
class _HubIdentity extends StatelessWidget {
  const _HubIdentity({required this.hub});

  final Hub hub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.glass,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.palette.glassBorder),
      ),
      child: Row(
        children: [
          HubTypeTile(hub: hub),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hub.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  HubLabels.type(hub.type),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          StatusPill(
            label: HubLabels.status(hub.status),
            tone: HubLabels.tone(hub.status),
          ),
        ],
      ),
    );
  }
}

/// El mapa quieto con el pin de la central, en vez de latitud y longitud
/// sueltas. Es el mismo `AppMap` del resto de la app.
class _HubMap extends StatelessWidget {
  const _HubMap({required this.point});

  final LatLng point;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 200,
        child: AppMap(
          center: point,
          zoom: 15,
          interactive: false,
          layers: [
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 42,
                  height: 42,
                  alignment: Alignment.topCenter,
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 42,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
