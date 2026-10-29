import 'package:flutter/material.dart';

import '../../../../core/widgets/rise_in.dart';

/// El andamiaje de los cuatro inicios: una sola lista que respeta la
/// muesca arriba y la barra flotante abajo. Los bloques entran en cascada;
/// las cuadrículas traen la suya.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          padding.top + 16,
          20,
          padding.bottom + 24,
        ),
        children: [
          for (final (i, child) in children.indexed)
            RiseIn(delay: RiseIn.stagger(i), child: child),
        ],
      ),
    );
  }
}
