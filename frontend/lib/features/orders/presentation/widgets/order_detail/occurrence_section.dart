import 'package:flutter/material.dart';

import '../../../../../core/widgets/detail_section.dart';
import '../../../../../core/widgets/error_banner.dart';
import 'occurrence_rules.dart';

/// La franja de una entrega de plan y lo que quien recibe puede hacer con
/// ella: confirmar, omitir o mover. Con menos de 2 horas o con dron, ya no.
class OccurrenceSection extends StatelessWidget {
  const OccurrenceSection({
    super.key,
    required this.rules,
    required this.busy,
    required this.onConfirm,
    required this.onSkip,
    required this.onMove,
  });

  final OccurrenceRules rules;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onSkip;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DetailSection(
      title: 'Tu entrega programada',
      icon: Icons.event_available_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rules.awaitsConfirmation && rules.changeable) ...[
            const ErrorBanner(
              message: 'Confirma tu entrega: si no, se omite 2 horas antes.',
              success: true,
            ),
            const SizedBox(height: 12),
          ],
          Text(rules.slotLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            rules.changeable
                ? 'La entrega se hace dentro de esa hora.'
                : 'Ya no se puede cambiar: faltan menos de 2 horas o ya '
                      'tiene dron.',
            style: theme.textTheme.bodySmall,
          ),
          if (rules.changeable) ...[
            const SizedBox(height: 14),
            _OccurrenceActions(section: this),
          ],
        ],
      ),
    );
  }
}

class _OccurrenceActions extends StatelessWidget {
  const _OccurrenceActions({required this.section});

  final OccurrenceSection section;

  @override
  Widget build(BuildContext context) {
    final s = section;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (s.rules.canConfirm)
          FilledButton.icon(
            onPressed: s.busy ? null : s.onConfirm,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Confirmar'),
          ),
        OutlinedButton.icon(
          onPressed: s.busy ? null : s.onMove,
          icon: const Icon(Icons.schedule_rounded),
          label: const Text('Mover'),
        ),
        TextButton(
          onPressed: s.busy ? null : s.onSkip,
          child: const Text('Omitir'),
        ),
      ],
    );
  }
}
