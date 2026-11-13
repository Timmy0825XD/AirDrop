import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/files/temp_file_share.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/message_view.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/prescription_checklist.dart';
import 'widgets/prescription_viewer/prescription_image_page.dart';
import 'widgets/prescription_viewer/prescription_pages_bar.dart';
import 'widgets/prescription_viewer/prescription_pdf_page.dart';

/// Abre la fórmula del pedido a pantalla completa (RF-27).
Future<void> showPrescription(BuildContext context, String orderId) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => PrescriptionViewerScreen(orderId: orderId),
    ),
  );
}

/// El visor de la fórmula para el despachador (RF-27): cada hoja ocupa la
/// pantalla, con zoom real; un PDF se ve por páginas. Arriba, la lista de
/// verificación y "Abrir con…" (una copia temporal que se borra al cerrar).
/// La fórmula vive en memoria solo mientras el visor está abierto.
class PrescriptionViewerScreen extends ConsumerStatefulWidget {
  const PrescriptionViewerScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<PrescriptionViewerScreen> createState() =>
      _PrescriptionViewerScreenState();
}

class _PrescriptionViewerScreenState
    extends ConsumerState<PrescriptionViewerScreen> {
  // Se lee al abrir: en `dispose` Riverpod ya no deja usar `ref`.
  late final TempFileShare _share;
  int _index = 0;
  final _turns = <int, int>{};

  @override
  void initState() {
    super.initState();
    _share = ref.read(tempFileShareProvider);
  }

  @override
  void dispose() {
    _share.clear();
    super.dispose();
  }

  Future<void> _openWith(PrescriptionFile file) async {
    try {
      await _share.open(bytes: file.bytes, name: file.name, mime: file.mime);
    } on Exception {
      if (mounted) {
        showErrorSnack(context, 'No se pudo abrir la fórmula con otra app.');
      }
    }
  }

  void _showChecklist() => showAppSheet<void>(
    context,
    builder: (_) => const Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: PrescriptionChecklist(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(orderPrescriptionProvider(widget.orderId));
    final current = files.value?.elementAtOrNull(_index);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fórmula'),
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Qué revisar',
            onPressed: _showChecklist,
            icon: const Icon(Icons.fact_check_outlined),
          ),
          IconButton(
            tooltip: 'Abrir con…',
            onPressed: current == null ? null : () => _openWith(current),
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: switch (files) {
        AsyncValue(:final value?) when value.isNotEmpty => _page(value),
        AsyncValue(:final value?) when value.isEmpty => const MessageView(
          icon: Icons.receipt_long_outlined,
          message: 'Este pedido no tiene fórmula.',
        ),
        AsyncError(:final error) => MessageView(
          icon: Icons.cloud_off_rounded,
          message: ApiException.messageOf(error),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: switch (files.value) {
        final value? when value.isNotEmpty => PrescriptionPagesBar(
          index: _index,
          count: value.length,
          onGo: (index) => setState(() => _index = index),
          onRotate: value[_index].isPdf
              ? null
              : () =>
                    setState(() => _turns[_index] = (_turns[_index] ?? 0) + 1),
        ),
        _ => null,
      },
    );
  }

  Widget _page(List<PrescriptionFile> files) {
    final file = files[_index];
    return file.isPdf
        ? PrescriptionPdfPage(key: ValueKey(_index), file: file)
        : PrescriptionImagePage(
            key: ValueKey(_index),
            file: file,
            quarterTurns: _turns[_index] ?? 0,
          );
  }
}
