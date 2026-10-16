import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../auth_field.dart';

/// Título, explicación, el correo y cuánto dura el código.
class ForgotPasswordForm extends StatelessWidget {
  const ForgotPasswordForm({
    super.key,
    required this.email,
    required this.errorText,
    required this.shakeCount,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController email;
  final String? errorText;
  final int shakeCount;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ForgotHeading(),
        const SizedBox(height: 26),
        IgnorePointer(
          ignoring: !enabled,
          child: AuthField(
            label: 'Correo electrónico',
            hint: 'nombre@correo.com',
            icon: Icons.mail_outline_rounded,
            controller: email,
            errorText: errorText,
            shakeCount: shakeCount,
            keyboardType: TextInputType.emailAddress,
            maxLength: FieldLimits.email,
            autofillHints: const [AutofillHints.email],
            onChanged: onChanged,
            onSubmitted: (_) => onSubmitted(),
          ),
        ),
        const SizedBox(height: 14),
        const _CodeLifetime(),
      ],
    );
  }
}

class _ForgotHeading extends StatelessWidget {
  const _ForgotHeading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Recuperar contraseña',
            style: theme.textTheme.displayMedium,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa el correo de tu cuenta. Ahí llega el código para crear '
          'una nueva contraseña.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _CodeLifetime extends StatelessWidget {
  const _CodeLifetime();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'El código dura 15 minutos.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

/// Confirmación del envío: abre su espacio y entra con un rebote corto.
/// Muestra el mensaje de Nest, que no dice si la cuenta existe.
class ForgotSentCard extends StatelessWidget {
  const ForgotSentCard({super.key, required this.message});

  /// En `null` mientras no se ha enviado; no ocupa espacio.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    return AnimatedSize(
      duration: const Duration(milliseconds: 420),
      curve: Curves.fastOutSlowIn,
      alignment: Alignment.topCenter,
      child: text == null
          ? const SizedBox(width: double.infinity)
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutBack,
              builder: (context, t, child) => Opacity(
                opacity: t.clamp(0, 1),
                child: Transform.translate(
                  offset: Offset(0, -12 * (1 - t)),
                  child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
                ),
              ),
              child: _SentBody(text: text),
            ),
    );
  }
}

class _SentBody extends StatelessWidget {
  const _SentBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: 18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: colors.primary,
              child: Icon(
                Icons.check_rounded,
                size: 16,
                color: colors.onPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$text Revisa también la carpeta de spam.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
