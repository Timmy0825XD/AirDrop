import 'package:flutter/material.dart';

import '../otp/otp_boxes_input.dart';
import 'reset_code_header.dart';
import 'reset_resend_button.dart';

/// Bloque del código en el restablecimiento: encabezado con el
/// temporizador, las cajas de dígitos y el botón de reenvío.
class ResetCodeSection extends StatelessWidget {
  const ResetCodeSection({
    super.key,
    required this.secondsRemaining,
    required this.countdownLabel,
    required this.onCodeChanged,
    this.onResend,
  });

  final int secondsRemaining;
  final String countdownLabel;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResetCodeHeader(
          secondsRemaining: secondsRemaining,
          countdownLabel: countdownLabel,
        ),
        const SizedBox(height: 10),
        Center(child: OtpBoxesInput(onChanged: onCodeChanged)),
        const SizedBox(height: 4),
        ResetResendButton(onPressed: onResend),
      ],
    );
  }
}