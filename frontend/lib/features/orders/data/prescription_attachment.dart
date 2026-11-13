import 'dart:convert';
import 'dart:typed_data';

/// Cada archivo de la fórmula pesa hasta 5 MB, como exige Nest (RU-25).
const prescriptionMaxBytes = 5 * 1024 * 1024;

/// Una fórmula de papel puede tener varias hojas: hasta 3 fotos.
const prescriptionMaxPhotos = 3;

const _pdfMime = 'application/pdf';

/// Un archivo de la fórmula que el solicitante adjuntó: un PDF o una foto.
class PrescriptionAttachment {
  const PrescriptionAttachment({
    required this.bytes,
    required this.mime,
    required this.name,
  });

  /// Arma el adjunto desde la extensión del archivo. Lanza
  /// [FormatException] con el mensaje para la persona si no sirve.
  factory PrescriptionAttachment.fromFile({
    required Uint8List bytes,
    required String name,
  }) {
    final mime = _mimeOf(name);
    if (mime == null) {
      throw const FormatException(
        'La fórmula debe ser un PDF o una foto JPG o PNG.',
      );
    }
    if (bytes.lengthInBytes > prescriptionMaxBytes) {
      throw const FormatException(
        'Cada archivo de la fórmula debe pesar hasta 5 MB.',
      );
    }
    return PrescriptionAttachment(bytes: bytes, mime: mime, name: name);
  }

  final Uint8List bytes;
  final String mime;
  final String name;

  bool get isPdf => mime == _pdfMime;

  /// Un archivo de `prescriptions` en el body (§19.2).
  Map<String, dynamic> toJson() => {
    'mime': mime,
    'base64': base64Encode(bytes),
  };
}

String? _mimeOf(String name) {
  final dot = name.lastIndexOf('.');
  final extension = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  return switch (extension) {
    'pdf' => _pdfMime,
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    _ => null,
  };
}

/// Suma lo recién elegido a la fórmula (RU-25): un PDF solo, o hasta 3
/// fotos. Un PDF reemplaza las fotos y una foto reemplaza el PDF, porque no
/// se mezclan. Lanza [FormatException] si pasa del límite.
List<PrescriptionAttachment> addPrescriptionFiles(
  List<PrescriptionAttachment> current,
  List<PrescriptionAttachment> picked,
) {
  if (picked.isEmpty) return current;
  final pdfs = picked.where((file) => file.isPdf).toList();
  if (pdfs.isNotEmpty) {
    if (picked.length > 1) {
      throw const FormatException('Elige un solo PDF, o fotos sin el PDF.');
    }
    return pdfs;
  }
  final photos = [...current.where((file) => !file.isPdf), ...picked];
  if (photos.length > prescriptionMaxPhotos) {
    throw const FormatException('La fórmula va en máximo 3 fotos.');
  }
  return photos;
}
