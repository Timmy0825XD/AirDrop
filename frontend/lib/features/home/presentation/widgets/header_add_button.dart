import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_icon_button.dart';

/// El botón de crear en el encabezado de una lista (`SectionHeader.trailing`):
/// un "+" del acento de 48 px. [label] es lo que dice el lector de pantalla
/// y el tooltip ("Nuevo dron"). Reemplaza a los botones flotantes, que
/// tapaban la última fila y peleaban con el botón del centro de la barra.
class HeaderAddButton extends StatelessWidget {
  const HeaderAddButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      icon: Icons.add_rounded,
      tooltip: label,
      onPressed: onPressed,
      active: true,
      size: 48,
    );
  }
}
