import 'package:flutter/material.dart';

import '../../../../../theme/app_icons.dart';

class RequesterDeliverySteps extends StatelessWidget {
  const RequesterDeliverySteps({super.key, required this.stage});
  final int stage;
  static const labels = [
    'Solicitud recibida',
    'Preparado en la central',
    'En camino',
    'Recibir con código',
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < labels.length; i++)
        _DeliveryStep(
          label: labels[i],
          completed: i < stage,
          current: i == stage,
          last: i == labels.length - 1,
        ),
    ],
  );
}

class _DeliveryStep extends StatelessWidget {
  const _DeliveryStep({
    required this.label,
    required this.completed,
    required this.current,
    required this.last,
  });
  final String label;
  final bool completed;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = completed
        ? 'completado'
        : current
        ? 'en curso'
        : 'pendiente';
    return Semantics(
      label: '$label, $state',
      excludeSemantics: true,
      child: Stack(
        children: [
          if (!last)
            Positioned(
              left: 10,
              top: 18,
              bottom: 0,
              child: Container(
                width: 2,
                color: completed ? colors.primary : colors.outlineVariant,
              ),
            ),
          Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepMark(completed: completed, current: current),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: current ? FontWeight.w700 : FontWeight.w400,
                      color: completed || current
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                    ),
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

class _StepMark extends StatelessWidget {
  const _StepMark({required this.completed, required this.current});
  final bool completed;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed ? colors.primary : colors.surface,
        border: Border.all(
          color: completed || current ? colors.primary : colors.outline,
          width: 2,
        ),
      ),
      child: completed
          ? Icon(AppIcons.check, size: 14, color: colors.onPrimary)
          : current
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary,
                ),
              ),
            )
          : null,
    );
  }
}
