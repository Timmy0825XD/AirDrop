import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../auth/data/auth_models.dart';
import '../../../../auth/presentation/widgets/auth_field.dart';
import '../../../../auth/presentation/widgets/document_type_labels.dart';

/// La imagen elegida: bytes y tipo.
typedef PickedPrescription = ({Uint8List bytes, String mime});

/// Abre el selector de archivos para la fórmula (JPG o PNG, hasta 2 MB,
/// como exige Nest). `null` si se cerró sin elegir; lanza
/// [FormatException] con el mensaje para mostrar si pesa de más.
Future<PickedPrescription?> pickPrescriptionImage() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png'],
  );
  if (files.isEmpty) return null;
  final file = files.first;
  final bytes = await file.readAsBytes();
  if (bytes.lengthInBytes > 2 * 1024 * 1024) {
    throw const FormatException(
      'La imagen de la fórmula debe pesar hasta 2 MB.',
    );
  }
  final png = (file.extension ?? '').toLowerCase() == 'png';
  return (bytes: bytes, mime: png ? 'image/png' : 'image/jpeg');
}

/// Bloque de la fórmula: a nombre de quién va (el documento de la cuenta,
/// con su nombre legible y no `citizenship_id`), el botón para adjuntarla
/// y la vista previa. Entra abriéndose cuando el insumo es bajo fórmula.
class PrescriptionPicker extends StatelessWidget {
  const PrescriptionPicker({
    super.key,
    required this.user,
    required this.image,
    required this.onPick,
    this.errorText,
  });

  final PublicUser? user;
  final Uint8List? image;
  final VoidCallback onPick;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final type = user?.documentType;
    final bytes = image;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('FÓRMULA MÉDICA', style: theme.textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            type == null
                ? 'La fórmula va a nombre del titular de la cuenta.'
                : 'Paciente: ${DocumentTypeLabels.label(type)} · '
                      '${user?.documentNumber ?? ''}',
            style: theme.textTheme.bodyMedium,
          ),
          if (bytes != null) _Preview(bytes: bytes),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(bytes == null ? 'Adjuntar fórmula' : 'Cambiar imagen'),
          ),
          AuthFieldError(message: errorText),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Imagen lista · ${(bytes.lengthInBytes / 1024).toStringAsFixed(0)} KB',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Icon(Icons.check_circle_rounded, color: theme.colorScheme.tertiary),
        ],
      ),
    );
  }
}
