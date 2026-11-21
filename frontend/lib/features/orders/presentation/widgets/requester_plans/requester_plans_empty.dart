import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/message_view.dart';
import '../../../../../theme/app_icons.dart';

class RequesterPlansEmpty extends StatelessWidget {
  const RequesterPlansEmpty({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: MessageView(
          icon: AppIcons.plans,
          title: 'Tu próxima entrega empieza aquí',
          message:
              'Elige el medicamento, los días y la hora. '
              'Te avisaremos antes de cada entrega para que confirmes.',
          action: FilledButton.icon(
            onPressed: () => context.push('/orders/plans/new'),
            icon: const Icon(AppIcons.createPlan),
            label: const Text('Crear entrega periódica'),
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text('A tu ritmo', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text(
        'Puedes ajustar el calendario o poner tus entregas en pausa '
        'desde el detalle de cada plan.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
