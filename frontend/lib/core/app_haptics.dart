import 'package:flutter/services.dart';

/// La vibración de la app, en un solo lugar: cada momento tiene la suya y
/// ninguna pantalla llama a `HapticFeedback` directo. Es corta y nunca es
/// el único aviso: siempre va con un cambio en la pantalla. En la web y en
/// los teléfonos sin motor no hace nada.
abstract final class AppHaptics {
  /// Un toque que prepara algo (el primer toque de "deslizar").
  static void tap() => HapticFeedback.selectionClick();

  /// Se confirmó una acción seria: pedir la urgencia, despegar.
  static void confirm() => HapticFeedback.mediumImpact();

  /// Salió bien: el pedido despegó, llegó o se entregó con el código.
  static void success() => HapticFeedback.lightImpact();

  /// Algo pide atención: falta un dato o el pedido vuelve con el paquete.
  static void warning() => HapticFeedback.heavyImpact();
}
