import 'package:flutter/material.dart';

import '../login/login_button.dart';

class ResetSuccessView extends StatelessWidget {
  const ResetSuccessView({
    super.key,
    required this.message,
    required this.onContinue,
  });

  final String message;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: _SuccessBadge(color: theme.colorScheme.tertiary),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 28),
        LoginButton(label: 'Ir al inicio de sesión', onPressed: onContinue),
      ],
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 28),
        ],
      ),
      child: Icon(Icons.check_rounded, size: 48, color: color),
    );
  }
}