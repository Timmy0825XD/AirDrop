import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../data/auth_models.dart';
import 'profile_edit_dialog.dart';

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

  /// "Cuenta personal" o "Central operativa vinculada", según tenga o no
  /// alguna central asignada. Con el contrato nuevo esto mira `hubIds`.
  static String organization(PublicUser user) =>
      user.hubId == null ? 'Cuenta personal' : 'Central operativa vinculada';

  /// Tope de caracteres que cada campo de datos admite, tomado del mismo
  /// lugar que los validadores para que no se duplique el número.
  static int limitFor(ProfileFieldType type) => switch (type) {
    ProfileFieldType.fullName => FieldLimits.fullName,
    ProfileFieldType.email => FieldLimits.email,
    ProfileFieldType.phone => FieldLimits.phoneDigits,
  };
}