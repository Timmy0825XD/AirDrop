import 'package:flutter/material.dart';

/// El relleno de una lista: deja libre el final para la barra flotante
/// (`RoleShell` suma su alto a `padding` en las pestañas) y, con [fab],
/// también para el botón flotante de la pantalla.
EdgeInsets listPadding(
  BuildContext context, {
  double top = 18,
  bool fab = false,
}) {
  final bottom = MediaQuery.paddingOf(context).bottom + (fab ? 88 : 32);
  return EdgeInsets.fromLTRB(20, top, 20, bottom);
}
