import 'package:flutter/material.dart';

enum ForgotMethod { email, sms }

class ForgotMethodChips extends StatelessWidget {
  const ForgotMethodChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ForgotMethod selected;
  final ValueChanged<ForgotMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MethodChip(
            icon: Icons.mail_outline_rounded,
            label: 'Vía Correo',
            selected: selected == ForgotMethod.email,
            onTap: () => onChanged(ForgotMethod.email),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MethodChip(
            icon: Icons.sms_outlined,
            label: 'Vía SMS / OTP',
            selected: selected == ForgotMethod.sms,
            onTap: () => onChanged(ForgotMethod.sms),
          ),
        ),
      ],
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = selected
        ? colors.primary
        : colors.onSurface.withValues(alpha: 0.6);

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 36,
          decoration: BoxDecoration(
            color: colors.onSurface.withValues(alpha: selected ? 0.1 : 0.04),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}