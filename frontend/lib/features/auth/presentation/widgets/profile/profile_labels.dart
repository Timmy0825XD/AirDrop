import 'package:flutter/material.dart';

import '../../../data/auth_models.dart';

/// Etiquetas y colores del rol. Vive en `data/` el enum y aquí la
/// presentación, para que la pantalla no repita el `switch`.
class ProfileLabels {
  ProfileLabels._();

  static String role(UserRole role) => switch (role) {
    UserRole.requester => 'Solicitante',
    UserRole.dispatcher => 'Despachador',
    UserRole.fleetOperator => 'Operador de flota',
    UserRole.admin => 'Administrador',
  };

  static Color roleColor(ColorScheme colors, UserRole role) => switch (role) {
    UserRole.requester => colors.primary,
    UserRole.dispatcher => colors.secondary,
    UserRole.fleetOperator => colors.tertiary,
    UserRole.admin => colors.error,
  };

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
