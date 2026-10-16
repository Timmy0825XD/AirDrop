import 'package:flutter/material.dart';

import '../check_mark.dart';

/// Consentimiento de datos (RNF-05) en su propia tarjeta. Sin marcarlo, el
/// botón de crear cuenta queda apagado.
class RegisterConsentRow extends StatelessWidget {
  const RegisterConsentRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      checked: value,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CheckBox(checked: value),
                const SizedBox(width: 14),
                Expanded(child: _ConsentText(theme: theme)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsentText extends StatelessWidget {
  const _ConsentText({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    return Text.rich(
      TextSpan(
        text: 'Acepto el tratamiento de datos personales y la ',
        children: [
          TextSpan(
            text: 'política de privacidad',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      style: theme.textTheme.bodySmall?.copyWith(
        color: colors.onSurfaceVariant,
        fontSize: 13,
        height: 1.55,
      ),
    );
  }
}

/// Casilla de 24 px: se llena de verde y el check se dibuja de punta a punta.
class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.fastOutSlowIn,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: checked ? colors.primary : colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: checked ? colors.primary : colors.outline,
          width: 1.5,
        ),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: checked ? 1 : 0),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOutCubic,
        builder: (context, t, _) => CustomPaint(
          painter: CheckMarkPainter(progress: t, color: colors.onPrimary),
        ),
      ),
    );
  }
}
