import 'package:flutter/material.dart';

import '../../../data/order_models.dart';

/// Una foto de la fórmula a pantalla completa (RF-27): se acerca con dos
/// dedos hasta 6×, con doble toque salta a 2,5× donde se tocó y vuelve, y
/// se gira de a 90° ([quarterTurns]). No vive dentro de un scroll: así el
/// zoom no pelea con nada.
class PrescriptionImagePage extends StatefulWidget {
  const PrescriptionImagePage({
    super.key,
    required this.file,
    this.quarterTurns = 0,
  });

  final PrescriptionFile file;
  final int quarterTurns;

  @override
  State<PrescriptionImagePage> createState() => _PrescriptionImagePageState();
}

class _PrescriptionImagePageState extends State<PrescriptionImagePage> {
  final _zoom = TransformationController();
  Offset _tap = Offset.zero;

  static const _doubleTapScale = 2.5;

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
    _zoom.value = zoomed
        ? Matrix4.identity()
        : (Matrix4.identity()
            ..translateByDouble(
              -_tap.dx * (_doubleTapScale - 1),
              -_tap.dy * (_doubleTapScale - 1),
              0,
              1,
            )
            ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _tap = details.localPosition,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _zoom,
        maxScale: 6,
        child: SizedBox.expand(
          child: RotatedBox(
            quarterTurns: widget.quarterTurns,
            child: Image.memory(
              widget.file.bytes,
              fit: BoxFit.contain,
              semanticLabel: 'Fórmula, ${widget.file.name}',
              // Una imagen dañada no muestra el error técnico del motor.
              errorBuilder: (context, _, _) => const _BrokenImage(),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrokenImage extends StatelessWidget {
  const _BrokenImage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No se pudo mostrar esta hoja. Ábrela con otra app o, si no se '
          'puede verificar, rechaza el pedido con ese motivo.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
