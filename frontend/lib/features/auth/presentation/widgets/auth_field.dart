import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Campo de auth: label en mayúsculas, caja de 56 px y error animado.
///
/// La pantalla valida y pasa [errorText]. Cada vez que sube [shakeCount] y
/// hay error, el campo tiembla, el borde se pone rojo y el mensaje baja
/// deslizándose. Con [onSubmitted] el teclado muestra "listo"; sin él,
/// "siguiente". A la derecha del label puede ir [trailing] (una nota o un
/// badge) y dentro de la caja, [icon] o un [prefix] propio.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.icon,
    this.prefix,
    this.trailing,
    this.errorText,
    this.shakeCount = 0,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.maxLines = 1,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? icon;
  final Widget? prefix;
  final Widget? trailing;
  final String? errorText;
  final int shakeCount;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;

  /// Más de 1 para un texto largo (la descripción de una urgencia).
  final int maxLines;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label: label, trailing: trailing),
        const SizedBox(height: 8),
        ShakeOnError(
          trigger: errorText == null ? 0 : shakeCount,
          child: _AuthInput(field: this),
        ),
        AuthFieldError(message: errorText),
      ],
    );
  }
}

/// Label en mayúsculas y, a la derecha, una nota o un badge opcional.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // Flexible a los dos lados: con letra grande del sistema o pantallas
    // angostas, se recortan en vez de desbordar.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Flexible(child: trailing!),
        ],
      ],
    );
  }
}

/// La caja de texto de [AuthField]. Con error, el borde pasa a rojo.
class _AuthInput extends StatelessWidget {
  const _AuthInput({required this.field});

  final AuthField field;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorBorder = field.errorText == null
        ? null
        : theme.inputDecorationTheme.errorBorder;
    return TextField(
      controller: field.controller,
      obscureText: field.obscureText,
      keyboardType: field.keyboardType,
      textInputAction: field.onSubmitted == null
          ? TextInputAction.next
          : TextInputAction.done,
      maxLength: field.maxLength,
      minLines: 1,
      maxLines: field.maxLines,
      autofillHints: field.autofillHints,
      onChanged: field.onChanged,
      onSubmitted: field.onSubmitted,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: field.hint,
        counterText: '',
        prefixIcon:
            field.prefix ??
            (field.icon == null ? null : Icon(field.icon, size: 20)),
        suffixIcon: field.suffix,
        enabledBorder: errorBorder,
        focusedBorder: errorBorder,
      ),
    );
  }
}

/// Sacude a su hijo en horizontal cada vez que cambia [trigger] (si no es
/// 0). La sacudida se amortigua sola: rápida al inicio, quieta al final.
class ShakeOnError extends StatelessWidget {
  const ShakeOnError({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (trigger == 0 || MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(math.sin(t * math.pi * 8) * 8 * (1 - t), 0),
        child: child,
      ),
      child: child,
    );
  }
}

/// El mensaje de error bajo el campo: abre su espacio y entra deslizándose
/// con un rebote corto. Con [message] en `null` no ocupa nada.
class AuthFieldError extends StatelessWidget {
  const AuthFieldError({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    return AnimatedSize(
      duration: const Duration(milliseconds: 360),
      curve: Curves.fastOutSlowIn,
      alignment: Alignment.topCenter,
      child: text == null
          ? const SizedBox(width: double.infinity)
          : TweenAnimationBuilder<double>(
              key: ValueKey(text),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 440),
              curve: Curves.easeOutBack,
              builder: (context, t, child) => Opacity(
                opacity: t.clamp(0, 1),
                child: Transform.translate(
                  offset: Offset(0, -10 * (1 - t)),
                  child: child,
                ),
              ),
              child: _ErrorLine(text: text),
            ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nota gris a la derecha del label ("8 a 72 caracteres").
class AuthFieldNote extends StatelessWidget {
  const AuthFieldNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Badge de marca a la derecha del label ("RECIBE EL CÓDIGO").
class AuthFieldBadge extends StatelessWidget {
  const AuthFieldBadge(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: primary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// Ojo para mostrar u ocultar la contraseña; el ícono cambia con una escala.
class AuthPasswordToggle extends StatelessWidget {
  const AuthPasswordToggle({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: visible ? 'Ocultar contraseña' : 'Mostrar contraseña',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          key: ValueKey(visible),
          size: 20,
        ),
      ),
    );
  }
}
