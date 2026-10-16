import 'package:flutter/material.dart';

import '../auth_field.dart';
import '../otp/otp_code_field.dart';

/// El código del correo: label, enlace para pedir otro y las seis cajas.
/// El enlace espera [secondsLeft] antes de habilitarse.
class ResetCodeSection extends StatelessWidget {
  const ResetCodeSection({
    super.key,
    required this.controller,
    required this.errorText,
    required this.shakeCount,
    required this.secondsLeft,
    required this.onResend,
  });

  final TextEditingController controller;
  final String? errorText;
  final int shakeCount;
  final int secondsLeft;

  /// En `null` mientras se está pidiendo otro código.
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final waiting = secondsLeft > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'CÓDIGO DE VERIFICACIÓN',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            TextButton(
              onPressed: waiting ? null : onResend,
              child: Text(
                waiting
                    ? 'Otro código en 0:${secondsLeft.toString().padLeft(2, '0')}'
                    : 'Solicitar otro código',
              ),
            ),
          ],
        ),
        OtpCodeField(
          controller: controller,
          collapse: kAlwaysDismissedAnimation,
          hasError: errorText != null,
          shakeCount: shakeCount,
          enabled: true,
          onSubmitted: () => FocusScope.of(context).nextFocus(),
        ),
        AuthFieldError(message: errorText),
      ],
    );
  }
}
