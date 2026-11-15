import 'package:flutter/material.dart';

import 'corridor_art.dart';

/// Un mensaje centrado en la pantalla: una lista vacía o un error. Lleva la
/// ilustración del corredor con el [icon] en una ficha, un [title] opcional,
/// el [message] y, con [action], un botón para salir del paso ("Crear
/// central", "Reintentar"). `MessageView.error` es el mismo mensaje con la
/// ruta cortada. Donde hay poco alto (una hoja, un panel sobre el mapa) se
/// queda en el ícono y el texto, sin ilustración.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.action,
  }) : _scene = CorridorScene.empty;

  /// Algo falló al traer los datos: dice qué pasó ([message] viene del
  /// backend o de la red) y, con [action], cómo reintentar.
  const MessageView.error({
    super.key,
    required this.message,
    this.title = 'No pudimos cargar esto',
    this.icon = Icons.cloud_off_rounded,
    this.action,
  }) : _scene = CorridorScene.broken;

  final String message;
  final String? title;
  final IconData? icon;
  final Widget? action;
  final CorridorScene _scene;

  /// Por debajo de este alto no cabe la ilustración.
  static const double _roomy = 340;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _MessageBody(view: this, roomy: box.maxHeight >= _roomy),
        ),
      ),
    );
  }
}

/// La ilustración (o el ícono suelto), el título, el mensaje y la acción.
class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.view, required this.roomy});

  final MessageView view;
  final bool roomy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (roomy) ...[
          CorridorArt(scene: view._scene, icon: view.icon),
          const SizedBox(height: 20),
        ] else if (view.icon != null) ...[
          Icon(view.icon, size: 40, color: muted),
          const SizedBox(height: 12),
        ],
        if (view.title != null) ...[
          Text(
            view.title!,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
        ],
        Text(
          view.message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: view.title == null ? null : muted,
          ),
        ),
        if (view.action != null) ...[const SizedBox(height: 16), view.action!],
      ],
    );
  }
}
