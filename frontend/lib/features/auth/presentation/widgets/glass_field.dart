import 'package:flutter/material.dart';

// Partes comunes de los campos de vidrio de LoginField y RegisterField:
// el borde redondeado y el ojo de la contraseña. Cada campo aporta sus
// colores; aquí vive solo lo que las dos pantallas repiten.

/// Borde redondeado de 14 con el color y el ancho que pida el campo.
/// `color == null` deja el campo sin borde (así lo usa el registro en reposo).
OutlineInputBorder glassBorder(Color? color, [double width = 1]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: color == null
        ? BorderSide.none
        : BorderSide(color: color, width: width),
  );
}

/// El ojo que muestra u oculta la contraseña. Quien tiene el estado resuelve
/// [onToggle]; este widget solo pinta y anuncia la acción al lector de pantalla.
class PasswordVisibilityToggle extends StatelessWidget {
  const PasswordVisibilityToggle({
    super.key,
    required this.hidden,
    required this.onToggle,
    required this.color,
    this.constraints,
  });

  final bool hidden;
  final VoidCallback onToggle;
  final Color color;

  /// `null` deja el tamaño por defecto de `IconButton` (48×48); el login pide
  /// 44×44 para que la caja quede más compacta.
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Mostrar u ocultar contraseña',
      constraints: constraints,
      onPressed: onToggle,
      icon: Icon(
        hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: color,
      ),
    );
  }
}
