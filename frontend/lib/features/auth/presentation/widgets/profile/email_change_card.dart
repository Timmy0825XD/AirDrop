import 'package:flutter/material.dart';

import '../../../../../core/widgets/error_banner.dart';
import '../../../../../core/widgets/form_sheet_card.dart';
import '../otp/otp_code_field.dart';

/// `ana@correo.com` → `a••@correo.com`: se reconoce sin mostrarlo entero.
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 1) return email;
  return '${email[0]}${'•' * (at - 1).clamp(2, 6)}${email.substring(at)}';
}

/// La tarjeta del código del correo nuevo: a dónde llegó, las seis cajas,
/// reenviar (con espera) y cancelar el cambio.
class EmailChangeCard extends StatelessWidget {
  const EmailChangeCard({
    super.key,
    required this.pendingEmail,
    required this.input,
    required this.collapse,
    required this.onSubmitted,
    required this.onResend,
    required this.onCancel,
    required this.secondsLeft,
    this.error,
    this.info,
    this.shakeCount = 0,
    this.enabled = true,
  });

  final String pendingEmail;
  final TextEditingController input;
  final Animation<double> collapse;
  final VoidCallback onSubmitted;
  final VoidCallback? onResend;
  final VoidCallback? onCancel;
  final int secondsLeft;
  final String? error;
  final String? info;
  final int shakeCount;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FormSheetCard(
      children: [
        if (error ?? info case final message?) ...[
          ErrorBanner(message: message, success: error == null),
          const SizedBox(height: 14),
        ],
        Text(
          'Escribe el código de 6 dígitos que enviamos a '
          '${maskEmail(pendingEmail)}. Vence en 10 minutos.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        OtpCodeField(
          controller: input,
          collapse: collapse,
          hasError: error != null,
          shakeCount: shakeCount,
          enabled: enabled,
          onSubmitted: onSubmitted,
        ),
        const SizedBox(height: 12),
        _EmailChangeActions(card: this),
      ],
    );
  }
}

/// Reenviar (con su espera) y cancelar el cambio.
class _EmailChangeActions extends StatelessWidget {
  const _EmailChangeActions({required this.card});

  final EmailChangeCard card;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: card.secondsLeft > 0 ? null : card.onResend,
          child: Text(
            card.secondsLeft > 0
                ? 'Reenviar en ${card.secondsLeft} s'
                : 'Reenviar código',
          ),
        ),
        TextButton(
          onPressed: card.onCancel,
          child: const Text('Cancelar cambio'),
        ),
      ],
    );
  }
}
