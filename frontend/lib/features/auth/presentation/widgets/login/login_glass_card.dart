import 'dart:ui';

import 'package:flutter/material.dart';

class LoginGlassCard extends StatelessWidget {
  const LoginGlassCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
          ),
          child: child,
        ),
      ),
    );
  }
}