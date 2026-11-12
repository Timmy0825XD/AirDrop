import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_palette.dart';
import 'tone_tile.dart';

/// Qué dice el aviso: salió bien, falló, solo informa o pide atención.
enum SnackTone { success, error, info, warning }

const _snackDuration = Duration(seconds: 4);

/// Muestra el resultado de una acción corta (crear, suspender, reactivar)
/// en una pastilla de vidrio que flota sobre la pantalla.
///
/// El texto es el que define el backend cuando viene en `ApiException`; acá
/// solo se presenta. Con [actionLabel] y [onAction] el aviso lleva un botón
/// (por ejemplo, "Ver vuelo").
void showAppSnack(
  BuildContext context,
  String message, {
  SnackTone tone = SnackTone.success,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final action = actionLabel == null || onAction == null
      ? null
      : () {
          messenger.hideCurrentSnackBar();
          onAction();
        };
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: GlassSnack(
          message: message,
          tone: tone,
          actionLabel: action == null ? null : actionLabel,
          onAction: action,
        ),
        duration: _snackDuration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
}

/// Atajo para el error de Nest (o de la app) tal cual llega.
void showErrorSnack(BuildContext context, String message) =>
    showAppSnack(context, message, tone: SnackTone.error);

/// El aviso: una tarjeta sólida con el ícono del tono, el texto y, si hay,
/// la acción. La línea de abajo se acorta mientras se ve.
class GlassSnack extends StatelessWidget {
  const GlassSnack({
    super.key,
    required this.message,
    required this.tone,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final SnackTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final color = snackColor(context, tone);
    final shape = BorderRadius.circular(16);
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: _snackDecoration(context, shape),
        child: ClipRRect(
          borderRadius: shape,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SnackRow(
                message: message,
                tone: tone,
                color: color,
                actionLabel: actionLabel,
                onAction: onAction,
              ),
              _SnackLifeBar(color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _SnackRow extends StatelessWidget {
  const _SnackRow({
    required this.message,
    required this.tone,
    required this.color,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final SnackTone tone;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
      child: Row(
        children: [
          ToneTile.icon(icon: snackIcon(tone), tone: color, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: color),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// La superficie sólida del tema con un filo fino y una sombra suave; el
/// color del tono va en el ícono y en la línea de abajo.
BoxDecoration _snackDecoration(BuildContext context, BorderRadius shape) {
  return BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: shape,
    border: Border.all(color: context.palette.glassBorder),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.16),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

/// El color de cada tono, desde el semáforo de la paleta.
Color snackColor(BuildContext context, SnackTone tone) {
  final palette = context.palette;
  return switch (tone) {
    SnackTone.success => palette.success,
    SnackTone.error => palette.danger,
    SnackTone.info => Theme.of(context).colorScheme.primary,
    SnackTone.warning => palette.warning,
  };
}

IconData snackIcon(SnackTone tone) => switch (tone) {
  SnackTone.success => Icons.check_rounded,
  SnackTone.error => Icons.error_outline_rounded,
  SnackTone.info => Icons.info_outline_rounded,
  SnackTone.warning => Icons.warning_amber_rounded,
};

/// La línea del borde inferior que se acorta mientras el aviso sigue a la
/// vista. Con "reducir movimiento" queda quieta.
class _SnackLifeBar extends StatelessWidget {
  const _SnackLifeBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: AppMotion.reduced(context) ? Duration.zero : _snackDuration,
      builder: (context, value, _) => Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: AppMotion.reduced(context) ? 1 : value,
          child: Container(height: 3, color: color),
        ),
      ),
    );
  }
}
