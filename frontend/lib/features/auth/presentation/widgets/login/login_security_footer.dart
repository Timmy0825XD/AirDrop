import 'package:flutter/material.dart';

/// Pie de la pantalla de login: sello de cifrado. Es un detalle de
/// confianza, no información funcional, por eso va al final y atenuado.
class LoginSecurityFooter extends StatelessWidget {
  const LoginSecurityFooter({super.key, this.label = 'Cifrado TLS 1.3 de Grado Clínico'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: 0.4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: theme.colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}