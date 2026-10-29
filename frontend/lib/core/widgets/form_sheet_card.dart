import 'package:flutter/material.dart';

import 'glass_card.dart';

/// La tarjeta de vidrio de un formulario. Apila sus [children] a lo ancho.
class FormSheetCard extends StatelessWidget {
  const FormSheetCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
