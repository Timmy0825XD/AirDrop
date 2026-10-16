import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/field_limits.dart';
import '../auth_field.dart';
import 'otp_boxes.dart';
import 'otp_success_check.dart';

/// El código de 6 dígitos: un solo campo invisible recibe lo que se escribe
/// (y el autocompletado del SMS o del correo) y seis cajas lo muestran.
///
/// Cuando [collapse] avanza, las cajas se juntan en el centro, se vuelven
/// verdes y se funden en el círculo con el check.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.collapse,
    required this.hasError,
    required this.shakeCount,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final Animation<double> collapse;
  final bool hasError;
  final int shakeCount;
  final bool enabled;
  final VoidCallback onSubmitted;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShakeOnError(
      trigger: widget.hasError ? widget.shakeCount : 0,
      child: SizedBox(
        height: OtpBoxes.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: OtpBoxes(
                controller: widget.controller,
                focus: _focus,
                collapse: widget.collapse,
                hasError: widget.hasError,
              ),
            ),
            Center(child: OtpSuccessCheck(progress: widget.collapse)),
            Positioned.fill(child: _hiddenInput()),
          ],
        ),
      ),
    );
  }

  /// El campo real: transparente y encima de las cajas para recibir toques.
  Widget _hiddenInput() {
    return Semantics(
      label: 'Código de verificación',
      child: Opacity(
        opacity: 0,
        child: TextField(
          controller: widget.controller,
          focusNode: _focus,
          enabled: widget.enabled,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: FieldLimits.otpDigits,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofillHints: const [AutofillHints.oneTimeCode],
          showCursor: false,
          enableInteractiveSelection: false,
          onSubmitted: (_) => widget.onSubmitted(),
          decoration: const InputDecoration.collapsed(hintText: ''),
        ),
      ),
    );
  }
}
