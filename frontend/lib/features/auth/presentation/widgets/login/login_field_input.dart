import 'package:flutter/material.dart';

import '../glass_field.dart';
import 'login_palette.dart';

/// El `TextFormField` de [LoginField]: decoración de vidrio, bordes según el
/// estado y el ojo de la contraseña. El foco vive en `LoginField`, que es
/// quien dibuja el resplandor al enfocar; la visibilidad vive aquí porque
/// solo este campo debe redibujarse al pulsar el ojo.
class LoginFieldInput extends StatefulWidget {
  const LoginFieldInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.validator,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.textInputAction,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final TextInputAction? textInputAction;

  @override
  State<LoginFieldInput> createState() => _LoginFieldInputState();
}

class _LoginFieldInputState extends State<LoginFieldInput> {
  late bool _hidden = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = LoginPalette.of(context);

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      validator: widget.validator,
      onChanged: widget.onChanged,
      obscureText: _hidden,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength,
      textInputAction: widget.textInputAction,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: p.muted.withValues(alpha: 0.7),
        ),
        counterText: '',
        filled: true,
        fillColor: p.field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: widget.obscureText
            ? PasswordVisibilityToggle(
                hidden: _hidden,
                onToggle: () => setState(() => _hidden = !_hidden),
                color: p.muted,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              )
            : null,
        border: glassBorder(p.fieldBorder),
        enabledBorder: glassBorder(p.fieldBorder),
        focusedBorder: glassBorder(p.accent, 1.5),
        errorBorder: glassBorder(p.error),
        focusedErrorBorder: glassBorder(p.error, 1.5),
        errorStyle: TextStyle(color: p.error),
      ),
    );
  }
}
