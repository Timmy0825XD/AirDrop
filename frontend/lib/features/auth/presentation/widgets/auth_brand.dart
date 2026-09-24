import 'package:flutter/material.dart';

class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primary.withValues(alpha: 0.12),
            border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
          ),
          child: Icon(
            Icons.flight_takeoff_rounded,
            color: colors.primary,
            size: 36,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'AirDrop',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'LOGÍSTICA AEROMÉDICA',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.primary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
