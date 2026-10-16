import 'package:flutter/material.dart';

/// Pide confirmar una acción que cambia el estado de algo (suspender o
/// reactivar). Sube como hoja desde abajo y oscurece el fondo. Devuelve
/// `true` solo si el usuario confirma.
///
/// [subject] es la ficha de lo que se va a tocar (la central o la
/// cuenta), para que se vea qué se confirma. Con [destructive] el botón
/// va en rojo.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Widget subject,
  required IconData icon,
  bool destructive = true,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _ConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      subject: subject,
      icon: icon,
      destructive: destructive,
    ),
  );
  return confirmed ?? false;
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.subject,
    required this.icon,
    required this.destructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final Widget subject;
  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tone = destructive ? colors.error : colors.primary;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetIcon(icon: icon, color: tone),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            subject,
            const SizedBox(height: 18),
            _SheetActions(confirmLabel: confirmLabel, color: tone),
          ],
        ),
      ),
    );
  }
}

/// El ícono de la hoja: entra con un giro corto y un rebote.
class _SheetIcon extends StatelessWidget {
  const _SheetIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Icon(icon, size: 30, color: color),
    );
    if (MediaQuery.disableAnimationsOf(context)) return box;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.rotate(
        angle: -0.4 * (1 - t),
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
      child: box,
    );
  }
}

class _SheetActions extends StatelessWidget {
  const _SheetActions({required this.confirmLabel, required this.color});

  final String confirmLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: shape,
              foregroundColor: colors.onSurface,
              side: BorderSide(color: colors.outline, width: 1.5),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: shape,
              backgroundColor: color,
              foregroundColor: colors.onPrimary,
            ),
            child: Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}
