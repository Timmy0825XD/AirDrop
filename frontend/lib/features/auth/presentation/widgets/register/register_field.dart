import 'package:flutter/material.dart';

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
  late bool _hidden = widget.obscureText;

  OutlineInputBorder _border(Color? color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: color == null
          ? BorderSide.none
          : BorderSide(color: color, width: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(theme),
        const SizedBox(height: 6),
        TextFormField(
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
            suffixIcon:
                widget.suffix ?? (widget.obscureText ? _toggle(colors) : null),
            border: _border(null),
            enabledBorder: _border(null),
            focusedBorder: _border(colors.primary.withValues(alpha: 0.7)),
            errorBorder: _border(colors.error.withValues(alpha: 0.7)),
            focusedErrorBorder: _border(colors.error),
          ),
        ),
      ],
    );
  }

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

  Widget? _icon(ColorScheme colors) {
    if (widget.icon == null) return null;
    return Icon(
      widget.icon,
      size: 20,
      color: colors.onSurface.withValues(alpha: 0.6),
    );
  }

  Widget _toggle(ColorScheme colors) {
    return IconButton(
      tooltip: 'Mostrar u ocultar contraseña',
      onPressed: () => setState(() => _hidden = !_hidden),
      icon: Icon(
        _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: colors.onSurface.withValues(alpha: 0.6),
      ),
    );
  }
}