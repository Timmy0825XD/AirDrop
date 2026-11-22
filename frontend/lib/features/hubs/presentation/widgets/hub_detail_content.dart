import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/clock/sim_clock.dart';
import '../../../../core/colombian_phone.dart';
import '../../../../core/widgets/app_map.dart';
import '../../../../core/widgets/form_section.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/phone_link.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_icons.dart';
import '../../data/hub_models.dart';
import 'hub_labels.dart';

/// Consulta de la central asignada; el despachador no administra sus datos.
class HubDetailContent extends StatelessWidget {
  const HubDetailContent({super.key, required this.hub});
  final Hub hub;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _HubIdentity(hub: hub),
      const SizedBox(height: 28),
      Text('Ubicación', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      _HubMap(point: LatLng(hub.latitude, hub.longitude)),
      const SizedBox(height: 10),
      Text(hub.address),
      const SizedBox(height: 28),
      FormSection(
        title: 'Contacto',
        children: [
          _HubContact(
            icon: AppIcons.contact,
            label: 'Teléfono',
            value: formatColombianPhone(hub.contactPhone),
            action: TextButton.icon(
              onPressed: () => callPhone(context, hub.contactPhone),
              icon: const Icon(AppIcons.contact),
              label: const Text('Llamar'),
            ),
          ),
          const Divider(height: 28),
          _HubContact(
            icon: AppIcons.mail,
            label: 'Correo',
            value: hub.contactEmail ?? 'Sin correo registrado',
          ),
          const Divider(height: 28),
          _HubContact(
            icon: AppIcons.destination,
            label: 'Coordenadas',
            value:
                '${hub.latitude.toStringAsFixed(6)}, ${hub.longitude.toStringAsFixed(6)}',
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        'Los datos de la central los administra el administrador.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _HubIdentity extends StatelessWidget {
  const _HubIdentity({required this.hub});
  final Hub hub;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(AppIcons.hub, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                hub.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          HubLabels.type(hub.type),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusPill(
              label: HubLabels.status(hub.status),
              tone: HubLabels.tone(hub.status),
            ),
            StatusPill(
              label: hub.poweredAt(simClock.now())
                  ? 'Con energía'
                  : 'Sin energía',
              tone: hub.poweredAt(simClock.now())
                  ? PillTone.positive
                  : PillTone.attention,
            ),
          ],
        ),
      ],
    ),
  );
}

class _HubContact extends StatelessWidget {
  const _HubContact({
    required this.icon,
    required this.label,
    required this.value,
    this.action,
  });
  final IconData icon;
  final String label, value;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 24),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(value),
            if (action != null)
              Align(alignment: Alignment.centerLeft, child: action),
          ],
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
