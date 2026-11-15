import 'package:flutter/material.dart';

import '../../../../../core/widgets/check_mark.dart';
import '../../../../../theme/app_palette.dart';

/// Consentimiento de datos (RNF-05) en su propia tarjeta. Sin marcarlo, el
/// botón de crear cuenta queda apagado.
class RegisterConsentRow extends StatelessWidget {
  const RegisterConsentRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onReadPolicy,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  /// Abre la política real (`GET /privacy/policy`, RF-50).
  final VoidCallback onReadPolicy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      checked: value,
      child: Material(
        color: context.palette.glass,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ConsentText(theme: theme),
                      TextButton(
                        onPressed: onReadPolicy,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(48, 48),
                          alignment: Alignment.centerLeft,
                        ),
                        child: const Text('Leer la política'),
                      ),
                    ],
                  ),
                ),
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
