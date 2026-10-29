import 'dart:ui' show ImageFilter;

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

/// La pastilla: desenfoca lo de atrás, se tiñe con el color del tono y
/// lleva su ícono, el texto y, si hay, la acción.
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
    final shape = BorderRadius.circular(22);
    return Semantics(
      liveRegion: true,
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: _glassDecoration(context, color, shape),
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

/// Vidrio: la superficie translúcida con un velo del tono arriba a la
/// izquierda, borde del mismo color y una sombra suave.
BoxDecoration _glassDecoration(
  BuildContext context,
  Color color,
  BorderRadius shape,
) {
  final surface = Theme.of(context).colorScheme.surface;
  return BoxDecoration(
    borderRadius: shape,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(
          color.withValues(alpha: 0.16),
          surface,
        ).withValues(alpha: 0.78),
        surface.withValues(alpha: 0.62),
      ],
    ),
    border: Border.all(color: color.withValues(alpha: 0.35)),
    boxShadow: [
      BoxShadow(
        color: context.palette.shadow,
        blurRadius: 28,
        offset: const Offset(0, 10),
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
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.9),
                  color.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
