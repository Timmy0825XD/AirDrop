import 'package:flutter/material.dart';

import '../glass_field.dart';

/// El `TextFormField` de [RegisterField]: decoración, prefijo, badge de
/// estado y el ojo de la contraseña. La etiqueta con su badge vive en
/// `RegisterField`, que la pinta encima del campo.
class RegisterFieldInput extends StatefulWidget {
  const RegisterFieldInput({
    super.key,
    required this.controller,
    required this.hint,
    this.validator,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.textInputAction,
    this.icon,
    this.prefix,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final IconData? icon;
  final Widget? prefix;
  final Widget? suffix;

  @override
  State<RegisterFieldInput> createState() => _RegisterFieldInputState();
}

class _RegisterFieldInputState extends State<RegisterFieldInput> {
  late bool _hidden = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      onChanged: widget.onChanged,
      obscureText: _hidden,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength,
      textInputAction: widget.textInputAction,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colors.onSurface.withValues(alpha: 0.4),
        ),
        counterText: '',
        filled: true,
        fillColor: colors.onSurface.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(vertical: 17),
        prefixIcon: widget.prefix ?? _icon(colors),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        suffixIcon: widget.suffix ??
            (widget.obscureText
                ? PasswordVisibilityToggle(
                    hidden: _hidden,
                    onToggle: () => setState(() => _hidden = !_hidden),
                    color: colors.onSurface.withValues(alpha: 0.6),
                  )
                : null),
        border: glassBorder(null),
        enabledBorder: glassBorder(null),
        focusedBorder: glassBorder(colors.primary.withValues(alpha: 0.7)),
        errorBorder: glassBorder(colors.error.withValues(alpha: 0.7)),
        focusedErrorBorder: glassBorder(colors.error),
      ),
    );
  }

  Widget? _icon(ColorScheme colors) {
    if (widget.icon == null) return null;
    return Icon(
      widget.icon,
      size: 20,
      color: colors.onSurface.withValues(alpha: 0.6),
    );
  }
}
