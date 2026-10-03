import 'package:flutter/material.dart';

import '../../../auth/data/auth_models.dart';
import '../../../../core/colombian_phone.dart';
import '../../data/user_models.dart';

/// Los campos del alta de cuenta en un solo objeto, más el estado del
/// selector de rol y de centrales.
///
/// No pinta nada: conserva los controladores, los libera y arma el body de
/// `POST /users`. Existe para no arrastrar siete parámetros por cada
/// widget del formulario.
class UserFormValues {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();

  /// Rol elegido y centrales seleccionadas: una sola para el despachador,
  /// una o más para el operador. [hubError] es el mensaje que pinta el
  /// formulario cuando esa regla no se cumple.
  UserRole role = UserRole.dispatcher;
  List<String> hubIds = const [];
  String? hubError;

  void dispose() {
    for (final controller in [name, email, phone, password]) {
      controller.dispose();
    }
  }

  /// El celular se normaliza aquí, igual que en el registro: Nest solo
  /// quita lo que no es dígito y exige 10 dígitos. El campo es opcional,
  /// así que vacío se envía como `null`. El correo baja a minúsculas,
  /// como el `@Transform` del DTO.
  CreateUserRequest request() {
    final phoneDigits = normalizeColombianPhone(phone.text);
    return CreateUserRequest(
      fullName: name.text.trim(),
      email: email.text.trim().toLowerCase(),
      phone: phoneDigits.isEmpty ? null : phoneDigits,
      password: password.text,
      role: role,
      hubIds: hubIds,
    );
  }
}

/// Regla de negocio de las centrales, la misma que valida
/// `UsersService.createInstitutional`: exactamente una para el
/// despachador, una o más para el operador. Devuelve `null` si está bien.
String? hubSelectionError(UserRole role, List<String> hubIds) {
  if (role == UserRole.dispatcher && hubIds.length != 1) {
    return 'El despachador debe quedar asignado a una sola central.';
  }
  if (hubIds.isEmpty) return 'Debes asignar al menos una central.';
  return null;
}
