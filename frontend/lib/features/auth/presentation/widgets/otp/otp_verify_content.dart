import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import 'otp_resend_card.dart';

/// Título y a qué correo llegó el código.
class OtpHeading extends StatelessWidget {
  const OtpHeading({super.key, required this.contactLabel});

  final String contactLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.55,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Verifica tu cuenta',
            style: theme.textTheme.displayMedium,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'Enviamos un código de ${FieldLimits.otpDigits} dígitos a\n',
            children: [
              TextSpan(
                text: contactLabel,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          style: muted,
        ),
      ],
    );
  }
}

/// Debajo del código: mientras se espera, cuándo vence y el reenvío; ya
/// verificado, la confirmación.
class OtpStatus extends StatelessWidget {
  const OtpStatus({
    super.key,
    required this.verified,
    required this.secondsLeft,
    required this.totalSeconds,
    required this.onResend,
  });

  final bool verified;
  final int secondsLeft;
  final int totalSeconds;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.fastOutSlowIn,
      switchOutCurve: Curves.fastOutSlowIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: verified
          ? const _Verified()
          : _Pending(
              secondsLeft: secondsLeft,
              totalSeconds: totalSeconds,
              onResend: onResend,
            ),
    );
  }
}

class _Pending extends StatelessWidget {
  const _Pending({
    required this.secondsLeft,
    required this.totalSeconds,
    required this.onResend,
  });

  final int secondsLeft;
  final int totalSeconds;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'El código vence en 10 minutos.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 22),
        OtpResendCard(
          secondsLeft: secondsLeft,
          totalSeconds: totalSeconds,
          onResend: onResend,
        ),
      ],
    );
  }
}

class _Verified extends StatelessWidget {
  const _Verified();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: SizedBox(
        width: double.infinity,
        child: Text(
          'Cuenta verificada',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
