import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/validators.dart';
import '../../../data/auth_models.dart';
import '../document_type_labels.dart';

/// Campo del perfil que se puede editar desde el diálogo.
enum ProfileFieldType { fullName, email, phone, document }

/// Lo que el diálogo necesita saber de cada campo: etiqueta, teclado,
/// tope, validador y cómo armar el `PATCH`. El tipo decide, el diálogo
/// solo arma el formulario.
extension ProfileFieldTypeRules on ProfileFieldType {
  String get label => switch (this) {
    ProfileFieldType.fullName => 'Nombre completo',
    ProfileFieldType.email => 'Correo electrónico',
    ProfileFieldType.phone => 'Celular',
    ProfileFieldType.document => 'Documento',
  };

  TextInputType get keyboardType => switch (this) {
    ProfileFieldType.fullName => TextInputType.name,
    ProfileFieldType.email => TextInputType.emailAddress,
    _ => TextInputType.phone,
  };

  int? get maxLength => switch (this) {
    ProfileFieldType.fullName => FieldLimits.fullName,
    ProfileFieldType.email => FieldLimits.email,
    _ => null,
  };

  /// El validador del documento depende del tipo elegido, porque cédula y
  /// PPT admiten formatos distintos.
  String? validate(String? value, DocumentType documentType) {
    return switch (this) {
      ProfileFieldType.fullName => Validators.name(value),
      ProfileFieldType.email => Validators.email(value),
      ProfileFieldType.phone => Validators.phone(value),
      ProfileFieldType.document =>
        DocumentTypeLabels.usesDigits(documentType)
            ? Validators.documentDigits(value)
            : Validators.documentPpt(value),
    };
  }

  /// El tipo y el número de documento se mandan siempre juntos.
  UpdateProfileRequest request(String value, DocumentType documentType) {
    return switch (this) {
      ProfileFieldType.fullName => UpdateProfileRequest(fullName: value),
      ProfileFieldType.email => UpdateProfileRequest(email: value),
      ProfileFieldType.phone => UpdateProfileRequest(phone: value),
      ProfileFieldType.document => UpdateProfileRequest(
        documentType: documentType,
        documentNumber: value,
      ),
    };
  }
}
