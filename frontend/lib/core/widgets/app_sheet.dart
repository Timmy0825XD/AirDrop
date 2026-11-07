import 'package:flutter/material.dart';

/// Toda hoja inferior de la app. Va al navegador raíz: así queda encima de
/// la barra flotante del rol y su velo la bloquea mientras está abierta
/// (en el navegador del `ShellRoute` la hoja quedaba debajo de la barra).
///
/// Adentro, cerrar con el `context` de la hoja (el del [builder]).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool showDragHandle = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: showDragHandle,
    builder: builder,
  );
}
