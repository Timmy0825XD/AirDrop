import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../auth/data/auth_models.dart';
import '../../../../../core/widgets/auth_field.dart';
import '../../../../auth/presentation/widgets/document_type_labels.dart';
import '../../../data/prescription_attachment.dart';
import '../../../data/triage_models.dart';

/// Abre el selector de archivos para la fórmula: un PDF, o una o varias
/// fotos JPG o PNG (RU-25). Vacío si se cerró sin elegir; lanza
/// [FormatException] con el mensaje para mostrar si un archivo no sirve.
Future<List<PrescriptionAttachment>> pickPrescriptionFiles() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
  );
  return [
    for (final file in files)
      PrescriptionAttachment.fromFile(
        bytes: await file.readAsBytes(),
        name: file.name,
      ),
  ];
}

/// Toma una foto de la fórmula con la cámara. La reduce a 2400 px y calidad
/// 85 para que una hoja se lea bien y quede muy por debajo de 5 MB.
Future<List<PrescriptionAttachment>> takePrescriptionPhoto() async {
  final photo = await ImagePicker().pickImage(
    source: ImageSource.camera,
    maxWidth: 2400,
    maxHeight: 2400,
    imageQuality: 85,
  );
  if (photo == null) return const [];
  final name = photo.name.contains('.') ? photo.name : '${photo.name}.jpg';
  return [
    PrescriptionAttachment.fromFile(
      bytes: await photo.readAsBytes(),
      name: name,
    ),
  ];
}

/// Bloque de la fórmula: a nombre de quién va, lo adjuntado (fotos o el
/// PDF, cada uno se puede quitar) y cómo agregar más. Entra abriéndose
/// cuando el insumo es bajo fórmula.
class PrescriptionPicker extends StatelessWidget {
  const PrescriptionPicker({
    super.key,
    required this.user,
    this.dependent,
    required this.files,
    required this.onTakePhoto,
    required this.onPickFiles,
    required this.onRemove,
    this.errorText,
  });

  final PublicUser? user;

  /// RF-42: la persona a cargo; la fórmula va a su nombre.
  final OrderPatient? dependent;
  final List<PrescriptionAttachment> files;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickFiles;
  final ValueChanged<int> onRemove;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Fórmula médica', style: theme.textTheme.labelSmall),
          const SizedBox(height: 6),
          _PatientLine(user: user, dependent: dependent),
          for (final (index, file) in files.indexed)
            PrescriptionFileTile(file: file, onRemove: () => onRemove(index)),
          const SizedBox(height: 10),
          PrescriptionButtons(
            files: files,
            onTakePhoto: onTakePhoto,
            onPickFiles: onPickFiles,
          ),
          AuthFieldError(message: errorText),
        ],
      ),
    );
  }
}

class _PatientLine extends StatelessWidget {
  const _PatientLine({required this.user, required this.dependent});

  final PublicUser? user;
  final OrderPatient? dependent;

  @override
  Widget build(BuildContext context) {
    final type = user?.documentType;
    final other = dependent;
    return Text(
      other != null
          ? 'Paciente: ${other.fullName} · ${other.documentType.label} '
                '${other.documentNumber}. La fórmula debe ir a su nombre.'
          : type == null
          ? 'La fórmula va a nombre del titular de la cuenta.'
          : 'Paciente: ${DocumentTypeLabels.label(type)} · '
                '${user?.documentNumber ?? ''}',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

/// Un archivo adjunto: la miniatura de la foto o el ícono del PDF, su peso
/// y la X para quitarlo.
class PrescriptionFileTile extends StatelessWidget {
  const PrescriptionFileTile({
    super.key,
    required this.file,
    required this.onRemove,
  });

  final PrescriptionAttachment file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kb = (file.bytes.lengthInBytes / 1024).round();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          _Thumbnail(file: file),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${file.name} · $kb KB',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          IconButton(
            tooltip: 'Quitar ${file.name}',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

/// La miniatura de la foto, o el ícono del PDF. Una foto que no se puede
/// dibujar muestra un ícono en vez de fallar.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.file});

  final PrescriptionAttachment file;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget icon(IconData data) => Container(
      width: 56,
      height: 56,
      color: colors.surface,
      child: Icon(data, color: colors.primary),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: file.isPdf
          ? icon(Icons.picture_as_pdf_rounded)
          : Image.memory(
              file.bytes,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => icon(Icons.image_outlined),
            ),
    );
  }
}

/// Cómo agregar: con la cámara o desde el teléfono, y qué se acepta. Con 3
/// fotos ya no se toman más.
class PrescriptionButtons extends StatelessWidget {
  const PrescriptionButtons({
    super.key,
    required this.files,
    required this.onTakePhoto,
    required this.onPickFiles,
  });

  final List<PrescriptionAttachment> files;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickFiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photos = files.where((file) => !file.isPdf).length;
    final full = photos >= prescriptionMaxPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: full ? null : onTakePhoto,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(photos == 0 ? 'Tomar foto' : 'Otra hoja'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickFiles,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Subir archivo'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          full
              ? 'Ya tienes 3 fotos. Quita una para cambiarla.'
              : 'Un PDF o hasta 3 fotos, de 5 MB cada una.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
