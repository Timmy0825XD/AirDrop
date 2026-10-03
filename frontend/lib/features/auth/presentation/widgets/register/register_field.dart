import 'package:flutter/material.dart';

import 'register_field_input.dart';

class RegisterField extends StatefulWidget {
  const RegisterField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.icon,
    this.prefix,
    this.suffix,
    this.badge,
    this.validator,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.textInputAction,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? icon;
  final Widget? prefix;
  final Widget? suffix;
  final String? badge;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final TextInputAction? textInputAction;

  @override
  State<RegisterField> createState() => _RegisterFieldState();
}

class _RegisterFieldState extends State<RegisterField> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(theme),
        const SizedBox(height: 6),
        RegisterFieldInput(
          controller: widget.controller,
          hint: widget.hint,
          validator: widget.validator,
          onChanged: widget.onChanged,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          maxLength: widget.maxLength,
          textInputAction: widget.textInputAction,
          icon: widget.icon,
          prefix: widget.prefix,
          suffix: widget.suffix,
        ),
      ],
    );
  }

  /// Etiqueta del campo con el badge opcional ("obligatorio", "opcional")
  /// alineado a la derecha.
  Widget _buildLabel(ThemeData theme) {
    final style = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(widget.label, style: style),
        if (widget.badge != null)
          Text(
            widget.badge!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}
