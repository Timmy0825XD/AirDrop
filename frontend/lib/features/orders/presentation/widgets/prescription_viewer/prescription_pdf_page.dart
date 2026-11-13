import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../data/order_models.dart';

/// La fórmula en PDF (RF-27): todas sus páginas una debajo de otra, con
/// zoom de dos dedos. El documento vive solo en memoria.
class PrescriptionPdfPage extends StatelessWidget {
  const PrescriptionPdfPage({super.key, required this.file});

  final PrescriptionFile file;

  @override
  Widget build(BuildContext context) {
    return PdfViewer.data(
      file.bytes,
      sourceName: file.name,
      params: PdfViewerParams(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        errorBannerBuilder: (context, _, _, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No se pudo abrir el PDF. Ábrelo con otra app o, si no se '
              'puede verificar, rechaza el pedido con ese motivo.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
