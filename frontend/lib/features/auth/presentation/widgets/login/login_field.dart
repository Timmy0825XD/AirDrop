import 'package:flutter/material.dart';

import 'login_field_input.dart';
import 'login_palette.dart';

/// Campo de vidrio con la etiqueta arriba (en minúsculas) y un resplandor
/// al enfocarlo. [icon] se conserva por compatibilidad, pero ya no se dibuja:
/// los íconos solo aparecen donde aportan (el ojo de la contraseña).
class LoginField extends StatefulWidget {
  const LoginField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.icon,
    this.validator,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.textInputAction,
  });

  final String label;
  final String hint;
  final IconData? icon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final TextInputAction? textInputAction;

  @override
  State<LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<LoginField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = LoginPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoginFieldLabel(widget.label),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              if (_focus.hasFocus)
                BoxShadow(color: p.accent.withValues(alpha: 0.35), blurRadius: 20),
            ],
          ),
          child: Semantics(
            label: widget.label,
            child: LoginFieldInput(
              controller: widget.controller,
              focusNode: _focus,
              hint: widget.hint,
              validator: widget.validator,
              onChanged: widget.onChanged,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              maxLength: widget.maxLength,
              textInputAction: widget.textInputAction,
            ),
          ),
        ),
      ],
    );
  }
}

/// La etiqueta visible del campo. Se queda fuera del `Semantics` para que el
/// lector de pantalla no anuncie la etiqueta dos veces: ya la declara el
/// propio campo.
class LoginFieldLabel extends StatelessWidget {
  const LoginFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: LoginPalette.of(context).ink,
        );
    return ExcludeSemantics(child: Text(text, style: style));
  }
}
