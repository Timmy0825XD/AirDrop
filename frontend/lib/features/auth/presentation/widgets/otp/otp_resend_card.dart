import 'package:flutter/material.dart';

/// Tarjeta del reenvío: cuenta regresiva con una barra que se vacía y, al
/// llegar a cero, el botón para pedir otro código.
class OtpResendCard extends StatelessWidget {
  const OtpResendCard({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
    required this.onResend,
  });

  final int secondsLeft;
  final int totalSeconds;

  /// En `null` mientras se está reenviando.
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 44,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.fastOutSlowIn,
            child: secondsLeft > 0
                ? _Countdown(seconds: secondsLeft)
                : _ResendButton(onPressed: onResend),
          ),
          const SizedBox(height: 12),
          _DrainBar(fraction: secondsLeft / totalSeconds),
        ],
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clock = '00:${seconds.toString().padLeft(2, '0')}';
    return Row(
      children: [
        Expanded(
          child: Text(
            'Puedes reenviarlo en',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          clock,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _ResendButton extends StatelessWidget {
  const _ResendButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Text(
            'Reenviar código',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.refresh_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

/// Barra fina que se vacía al ritmo de la cuenta regresiva.
class _DrainBar extends StatelessWidget {
  const _DrainBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 4,
        color: colors.surfaceContainerHighest,
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 950),
          curve: Curves.fastOutSlowIn,
          widthFactor: fraction.clamp(0, 1),
          heightFactor: 1,
          child: ColoredBox(color: colors.primary),
        ),
      ),
    );
  }
}
