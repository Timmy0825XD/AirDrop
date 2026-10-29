import 'package:flutter/widgets.dart';

/// Tiempos y curvas de la app. Nunca `linear` ni `ease`: entrar con
/// `fastOutSlowIn`, rebotar con `easeOutBack` y cambiar de pantalla con
/// `easeInOutCubic`.
abstract final class AppMotion {
  static const tap = Duration(milliseconds: 120);
  static const quick = Duration(milliseconds: 220);
  static const enter = Duration(milliseconds: 320);
  static const page = Duration(milliseconds: 380);
  static const bounce = Duration(milliseconds: 420);
  static const count = Duration(milliseconds: 900);

  static const Curve enterCurve = Curves.fastOutSlowIn;
  static const Curve bounceCurve = Curves.easeOutBack;
  static const Curve pageCurve = Curves.easeInOutCubic;

  /// `true` si el sistema pide reducir movimiento: todo salta al final.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], o cero con "reducir movimiento".
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
