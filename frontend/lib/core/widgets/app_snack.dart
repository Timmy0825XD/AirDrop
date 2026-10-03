import 'package:flutter/material.dart';

/// Muestra el resultado de una acción corta (crear, suspender, reactivar).
///
/// El texto es el que define el backend cuando viene en `ApiException`; acá
/// solo se presenta. El fondo queda por defecto para que el mensaje mantenga
/// el contraste en tema claro y oscuro (RNF-10).
void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}
