import 'package:flutter/material.dart';

import 'login_alert.dart';

/// Mensaje de error o de éxito del formulario, con animación de entrada
/// y salida. Si [message] es `null` no ocupa espacio.
class AuthFormAlert extends StatelessWidget {
  const AuthFormAlert({
    super.key,
    required this.message,
    required this.onDismiss,
    this.topPadding = 0,
    this.bottomPadding = 0,
  });

  final String? message;
  final VoidCallback onDismiss;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final text = message;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: text == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                key: ValueKey(text),
                padding: EdgeInsets.only(
                  top: topPadding,
                  bottom: bottomPadding,
                ),
                child: LoginAlert(message: text, onDismiss: onDismiss),
              ),
      ),
    );
  }
}