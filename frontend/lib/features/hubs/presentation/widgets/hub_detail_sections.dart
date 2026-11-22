import 'package:flutter/material.dart';

import '../../../../core/clock/sim_clock.dart';
import '../../../../core/colombian_phone.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/phone_link.dart';
import '../../../../theme/app_icons.dart';
import '../../../../theme/app_palette.dart';
import '../../data/hub_models.dart';
import 'hub_labels.dart';

class HubDetailIdentity extends StatelessWidget {
  const HubDetailIdentity({super.key, required this.hub});
  final Hub hub;
  @override
  Widget build(BuildContext context) => GlassCard(
    radius: 16,
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        const Icon(AppIcons.hub, size: 38),
        Container(
          width: 1,
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: Theme.of(context).colorScheme.outline,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final inline =
                  box.maxWidth >= 180 &&
                  MediaQuery.textScalerOf(context).scale(14) < 20;
              final name = _HubIdentityName(hub: hub);
              return inline
                  ? Row(
                      children: [
                        Expanded(child: name),
                        const SizedBox(width: 12),
                        _HubStatus(hub: hub),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        name,
                        const SizedBox(height: 8),
                        _HubStatus(hub: hub),
                      ],
                    );
            },
          ),
        ),
      ],
    ),
  );
}

class _HubIdentityName extends StatelessWidget {
  const _HubIdentityName({required this.hub});
  final Hub hub;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        hub.name,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(
        HubLabels.type(hub.type),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _HubStatus extends StatelessWidget {
  const _HubStatus({required this.hub});
  final Hub hub;
  @override
  Widget build(BuildContext context) {
    final color = hub.isActive
        ? context.palette.success
        : context.palette.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        HubLabels.status(hub.status),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class HubEnergyRow extends StatelessWidget {
  const HubEnergyRow({super.key, required this.hub});
  final Hub hub;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ClockView?>(
    valueListenable: simClock.view,
    builder: (context, _, _) {
      final powered = hub.poweredAt(simClock.now());
      return GlassCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: powered
                    ? Theme.of(context).colorScheme.primary
                    : context.palette.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                powered ? 'Con energía' : 'Sin energía',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class HubContactSection extends StatelessWidget {
  const HubContactSection({super.key, required this.hub});
  final Hub hub;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Contacto', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      GlassCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _HubContactRow(
              icon: AppIcons.contact,
              label: 'Teléfono',
              value: formatColombianPhone(hub.contactPhone),
              action: OutlinedButton(
                onPressed: () => callPhone(context, hub.contactPhone),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Llamar'),
              ),
            ),
            const Divider(height: 1),
            _HubContactRow(
              icon: AppIcons.mail,
              label: 'Correo',
              value: hub.contactEmail ?? 'Sin correo registrado',
            ),
          ],
        ),
      ),
    ],
  );
}

class _HubContactRow extends StatelessWidget {
  const _HubContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.action,
  });
  final IconData icon;
  final String label, value;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      children: [
        Icon(icon, size: 27),
        Container(
          width: 1,
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          color: Theme.of(context).colorScheme.outline,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final inline =
                  box.maxWidth >= 180 &&
                  MediaQuery.textScalerOf(context).scale(14) <= 18;
              final text = _HubContactText(label: label, value: value);
              return action != null && inline
                  ? Row(
                      children: [
                        Expanded(child: text),
                        const SizedBox(width: 12),
                        action!,
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        text,
                        if (action != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: action!,
                          ),
                        ],
                      ],
                    );
            },
          ),
        ),
      ],
    ),
  );
}

class _HubContactText extends StatelessWidget {
  const _HubContactText({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 3),
      Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
