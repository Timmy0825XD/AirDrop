import 'package:flutter/material.dart';

import '../../../../core/colombian_phone.dart';
import '../../../../core/validators.dart';
import '../../../auth/data/auth_models.dart';
import '../../data/user_models.dart';

/// Los campos del alta de cuenta.
enum UserInput { name, email, phone, password, hubs }

/// Los campos del alta de cuenta en un solo objeto, más el rol y las
/// centrales elegidas.
///
/// No pinta nada: conserva los controladores, valida con `Validators`
/// (los mismos mensajes de Nest) y arma el body de `POST /users`.
class UserFormValues {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();

  UserRole role = UserRole.dispatcher;

  /// Una sola para el despachador, una o más para el operador.
  List<String> hubIds = const [];

  void dispose() {
    for (final controller in [name, email, phone, password]) {
      controller.dispose();
    }
  }

  /// Cambia el rol; al volver a despachador solo cabe una central.
  void selectRole(UserRole value) {
    role = value;
    if (role == UserRole.dispatcher && hubIds.length > 1) {
      hubIds = [hubIds.first];
    }
  }

  /// Toca una central: el despachador la cambia, el operador la suma o
  /// la quita.
  void toggleHub(String id) {
    if (role == UserRole.dispatcher) {
      hubIds = [id];
    } else {
      hubIds = hubIds.contains(id)
          ? hubIds.where((hubId) => hubId != id).toList()
          : [...hubIds, id];
    }
  }

  /// Un mensaje por campo con error; vacío si todo está bien. El celular
  /// es opcional.
  Map<UserInput, String> validate() {
    final errors = <UserInput, String?>{
      UserInput.name: Validators.name(name.text),
      UserInput.email: Validators.email(email.text),
      UserInput.phone: phone.text.trim().isEmpty
          ? null
          : Validators.phone(phone.text),
      UserInput.password: Validators.password(password.text),
      UserInput.hubs: hubSelectionError(role, hubIds),
    };
    return {
      for (final entry in errors.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }

  /// El celular se normaliza aquí, igual que en el registro: Nest solo
  /// quita lo que no es dígito y exige 10 dígitos; vacío se envía como
  /// `null`. El correo baja a minúsculas, como el `@Transform` del DTO.
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
