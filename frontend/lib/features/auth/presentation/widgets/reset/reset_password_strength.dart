import 'package:flutter/material.dart';

import '../../../../../core/validators.dart';

class ResetPasswordStrength extends StatelessWidget {
  const ResetPasswordStrength({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: value.text.isEmpty
            ? const SizedBox(width: double.infinity)
            : _StrengthBody(text: value.text),
      ),
    );
  }
}

class _StrengthBody extends StatelessWidget {
  const _StrengthBody({required this.text});

  final String text;

  int _level(bool valid) {
    if (!valid) return 1;
    var score = 2;
    if (text.length >= 12) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(text)) score++;
    return score.clamp(2, 4);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final issue = Validators.password(text);
    final level = _level(issue == null);
    final tone = level == 1
        ? colors.error
        : level == 2
        ? colors.primary
        : colors.tertiary;
    const labels = ['', 'Débil', 'Aceptable', 'Segura', 'Muy segura'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                issue == null ? Icons.verified_outlined : Icons.info_outline,
                size: 16,
                color: tone,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  issue ?? 'Cumple los requisitos de la clave.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Text(
                labels[level],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _StrengthBars(level: level, tone: tone),
        ],
      ),
    );
  }
}

class _StrengthBars extends StatelessWidget {
  const _StrengthBars({required this.level, required this.tone});

  final int level;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final off = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);

    return Row(
      children: List.generate(4, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 3 ? 6 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 4,
              decoration: BoxDecoration(
                color: index < level ? tone : off,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}