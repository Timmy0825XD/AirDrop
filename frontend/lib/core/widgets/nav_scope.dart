import 'package:flutter/widgets.dart';

/// Lo que la barra flotante le cuenta a la pantalla que tiene debajo: si
/// la pantalla es un destino de la barra (entonces no lleva "volver") y si
/// hay barra en absoluto.
class NavScope extends InheritedWidget {
  const NavScope({super.key, required this.isTabRoot, required super.child});

  final bool isTabRoot;

  /// `true` cuando la pantalla es un destino de la barra del rol.
  static bool isTabRootOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavScope>()?.isTabRoot ??
      false;

  @override
  bool updateShouldNotify(NavScope old) => old.isTabRoot != isTabRoot;
}
