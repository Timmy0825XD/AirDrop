import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/field_limits.dart';
import '../login/login_alert.dart';
import '../login/login_button.dart';
import 'otp_boxes_input.dart';
import 'otp_resend_section.dart';
import 'otp_shield_badge.dart';

/// Contenido de la verificación del código. No sabe de contactos ni de
/// temporizadores: recibe el contacto ya formateado, el estado del
/// reenvío y los callbacks.
class OtpVerifyContent extends StatelessWidget {
  const OtpVerifyContent({
    super.key,
    required this.contactLabel,
    required this.onCodeChanged,
    required this.onResend,
    required this.onSubmit,
    required this.errorMessage,
    required this.noticeMessage,
    required this.onDismissMessage,
    this.secondsRemaining = 0,
    this.countdownLabel = '',
    this.canResend = false,
    this.isLoading = false,
  });

  final String contactLabel;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback? onResend;
  final VoidCallback onSubmit;
  final String? errorMessage;
  final String? noticeMessage;
  final VoidCallback onDismissMessage;
  final int secondsRemaining;
  final String countdownLabel;
  final bool canResend;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: OtpShieldBadge()),
        const SizedBox(height: 24),
        _Heading(contactLabel: contactLabel),
        const SizedBox(height: 24),
        _Alert(
          errorMessage: errorMessage,
          noticeMessage: noticeMessage,
          onDismiss: onDismissMessage,
        ),
        Center(child: OtpBoxesInput(onChanged: onCodeChanged)),
        const SizedBox(height: 20),
        Center(
          child: OtpResendSection(
            secondsRemaining: secondsRemaining,
            countdownLabel: countdownLabel,
            onResend: canResend ? onResend : null,
          ),
        ),
        const SizedBox(height: 24),
        LoginButton(
          label: 'Verificar',
          isLoading: isLoading,
          onPressed: onSubmit,
        ),
        const SizedBox(height: 24),
        const _SupportRow(),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.contactLabel});

  final String contactLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        Text(
          'Verifica tu cuenta',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enviamos un código de ${FieldLimits.otpDigits} dígitos a',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          contactLabel,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Alert extends StatelessWidget {
  const _Alert({
    required this.errorMessage,
    required this.noticeMessage,
    required this.onDismiss,
  });

  final String? errorMessage;
  final String? noticeMessage;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final error = errorMessage;
    final message = error ?? noticeMessage;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: message == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                key: ValueKey(message),
                padding: const EdgeInsets.only(bottom: 18),
                child: LoginAlert(
                  message: message,
                  success: error == null,
                  onDismiss: onDismiss,
                ),
              ),
      ),
    );
  }
}

class _SupportRow extends StatelessWidget {
  const _SupportRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Problemas con el código?',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        TextButton(
          onPressed: () => context.go('/forgot-password'),
          child: Text(
            'Recuperar acceso',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}