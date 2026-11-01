import 'package:flutter/material.dart';

import '../../theme/app_surfaces.dart';

/// La tarjeta de un formulario: la misma superficie que la hoja del auth
/// (grafito que baja a casi negro en oscuro, blanco en claro) y sus campos
/// con borde visible. Apila sus [children] a lo ancho.
class FormSheetCard extends StatelessWidget {
  const FormSheetCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: AppSurfaces.sheet(
        context,
        radius: BorderRadius.circular(28),
        lift: false,
      ),
      child: Theme(
        data: theme.copyWith(inputDecorationTheme: AppSurfaces.fields(theme)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
