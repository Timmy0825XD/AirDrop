import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/widgets/app_map.dart';
import '../../../../theme/app_icons.dart';
import '../../data/hub_models.dart';
import 'hub_detail_sections.dart';

/// Consulta compartida de la central, con contacto y ubicación reales.
class HubDetailContent extends StatelessWidget {
  const HubDetailContent({super.key, required this.hub});
  final Hub hub;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HubDetailIdentity(hub: hub),
      const SizedBox(height: 12),
      HubEnergyRow(hub: hub),
      const SizedBox(height: 24),
      Text('Ubicación', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      _HubMap(point: LatLng(hub.latitude, hub.longitude)),
      const SizedBox(height: 10),
      Text(hub.address),
      const SizedBox(height: 4),
      Text(
        'Coordenadas: ${hub.latitude.toStringAsFixed(6)}, ${hub.longitude.toStringAsFixed(6)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 24),
      HubContactSection(hub: hub),
      const SizedBox(height: 14),
      Text(
        'Los datos de la central los administra el administrador.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _HubMap extends StatelessWidget {
  const _HubMap({required this.point});
  final LatLng point;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Ubicación de la central en el mapa',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
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
                    AppIcons.destination,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
