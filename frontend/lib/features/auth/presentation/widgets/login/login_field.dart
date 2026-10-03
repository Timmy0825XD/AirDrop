import 'package:flutter/material.dart';

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
  late bool _hidden = widget.obscureText;

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

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = LoginPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: p.ink,
            ),
          ),
        ),
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
            child: _input(theme, p),
          ),
        ),
      ],
    );
  }

  Widget _input(ThemeData theme, LoginPalette p) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focus,
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
        suffixIcon: widget.obscureText ? _toggle(p.muted) : null,
        border: _border(p.fieldBorder),
        enabledBorder: _border(p.fieldBorder),
        focusedBorder: _border(p.accent, 1.5),
        errorBorder: _border(p.error),
        focusedErrorBorder: _border(p.error, 1.5),
        errorStyle: TextStyle(color: p.error),
      ),
    );
  }

  Widget _toggle(Color color) {
    return IconButton(
      tooltip: 'Mostrar u ocultar contraseña',
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      onPressed: () => setState(() => _hidden = !_hidden),
      icon: Icon(
        _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: color,
      ),
    );
  }
}