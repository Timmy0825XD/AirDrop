import 'package:flutter/material.dart';

import '../auth_ambience.dart';

class ForgotHeader extends StatelessWidget {
  const ForgotHeader({super.key, required this.onBack});

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
            'Recuperar contraseña',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              letterSpacing: -0.2,
            ),
          ),
        ),
        const _SecureChip(),
      ],
    );
  }
}

class _SecureChip extends StatelessWidget {
  const _SecureChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthPulsingDot(color: colors.primary),
          const SizedBox(width: 6),
          Text(
            'SEGURO',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}