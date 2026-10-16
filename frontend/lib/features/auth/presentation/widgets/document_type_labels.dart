import '../../data/auth_models.dart';

/// Copy en español de los tipos de documento. Sigue la convención del
/// código: el enum vive en `data/` y el texto en `presentation/`, como
/// hace `ProfileLabels` con el rol. Lo usan el registro y el perfil.
class DocumentTypeLabels {
  DocumentTypeLabels._();

  static String label(DocumentType type) => switch (type) {
    DocumentType.citizenshipId => 'Cédula de ciudadanía',
    DocumentType.foreignerId => 'Cédula de extranjería',
    DocumentType.ppt => 'PPT',
  };

  /// Hint del campo del número, con un ejemplo de cada formato: las dos
  /// cédulas son solo dígitos y el PPT admite letras.
  static String hint(DocumentType type) => switch (type) {
    DocumentType.citizenshipId => 'Ej. 1065123456',
    DocumentType.foreignerId => 'Ej. 1065123456',
    DocumentType.ppt => 'Ej. AB123456',
  };

  /// Cuántos caracteres admite cada tipo, para la nota junto al label.
  static String lengthNote(DocumentType type) =>
      usesDigits(type) ? '6 a 10 dígitos' : '6 a 15 letras o números';

  /// Versión corta para el selector segmentado, donde cada pestaña tiene
  /// un tercio del ancho de la pantalla.
  static String shortLabel(DocumentType type) => switch (type) {
    DocumentType.citizenshipId => 'Cédula',
    DocumentType.foreignerId => 'Extranjería',
    DocumentType.ppt => 'PPT',
  };

  /// Cédula de ciudadanía y de extranjería comparten el regex de solo
  /// dígitos; el PPT admite letras y números. Refleja
  /// `DOCUMENT_PATTERNS` de `backend/src/auth/auth.rules.ts`.
  static bool usesDigits(DocumentType type) => type != DocumentType.ppt;
}
