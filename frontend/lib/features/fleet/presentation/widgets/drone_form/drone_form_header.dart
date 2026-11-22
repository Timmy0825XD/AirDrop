import 'package:flutter/material.dart';
import '../../../../../core/widgets/compact_form_header.dart';

/// Conserva la fila aprobada y la comparte con los demás formularios.
class DroneFormHeader extends StatelessWidget {
  const DroneFormHeader({
    super.key,
    required this.hubName,
    required this.onBack,
  });
  final String hubName;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) =>
      CompactFormHeader(title: 'Nuevo dron', subtitle: hubName, onBack: onBack);
}
