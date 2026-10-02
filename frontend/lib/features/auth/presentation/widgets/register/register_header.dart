import 'package:flutter/material.dart';

import '../auth_ambience.dart';

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        IconButton(
          tooltip: 'Volver',
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: colors.onSurface.withValues(alpha: 0.08),
            minimumSize: const Size(40, 40),
          ),
          icon: const Icon(Icons.arrow_back, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Crear cuenta',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const RegisterStatusChip(),
      ],
    );
  }
}

class RegisterStatusChip extends StatelessWidget {
  const RegisterStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthPulsingDot(color: colors.tertiary, size: 8),
          const SizedBox(width: 6),
          Text(
            'NODO ACTIVO',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.tertiary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}