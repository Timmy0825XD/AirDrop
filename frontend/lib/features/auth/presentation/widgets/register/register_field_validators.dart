import 'package:flutter/material.dart';

/// Agrupa los validadores y el callback de limpieza de error, para que
/// la pantalla no los pase uno por uno en cada campo.
class RegisterFieldValidators {
  const RegisterFieldValidators({
    required this.name,
    required this.documentNumber,
    required this.phone,
    required this.email,
    required this.password,
    required this.onChanged,
  });

  final String? Function(String?)? name;
  final String? Function(String?)? documentNumber;
  final String? Function(String?)? phone;
  final String? Function(String?)? email;
  final String? Function(String?)? password;
  final ValueChanged<String> onChanged;
}
