import 'package:flutter/material.dart';

/// Toda hoja inferior de la app. Va al navegador raíz: así queda encima de
/// la barra flotante del rol y su velo la bloquea mientras está abierta
/// (en el navegador del `ShellRoute` la hoja quedaba debajo de la barra).
///
/// Adentro, cerrar con el `context` de la hoja (el del [builder]).
///
/// Siempre lleva la barrita de arrastre: el contenido de las hojas arranca
/// sin margen arriba y la barrita es la que lo separa del borde.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: builder,
  );
}
