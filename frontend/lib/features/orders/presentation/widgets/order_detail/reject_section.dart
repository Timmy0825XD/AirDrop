import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/widgets/detail_section.dart';
import '../../../../auth/presentation/widgets/auth_field.dart';

/// Rechazar un pedido en `received`, con un motivo obligatorio que luego
/// ve el solicitante. Empieza cerrado ("Rechazar pedido") para que no
/// compita con autorizar; al abrirlo aparece el motivo.
class RejectSection extends StatefulWidget {
  const RejectSection({
    super.key,
    required this.reason,
    required this.errorText,
    required this.shakeCount,
    required this.busy,
    required this.onReject,
  });

  final TextEditingController reason;
  final String? errorText;
  final int shakeCount;
  final bool busy;
  final VoidCallback onReject;

  @override
  State<RejectSection> createState() => _RejectSectionState();
}

class _RejectSectionState extends State<RejectSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final button = OutlinedButton.icon(
      onPressed: widget.busy
          ? null
          : _open
          ? widget.onReject
          : () => setState(() => _open = true),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        foregroundColor: colors.error,
        side: BorderSide(color: colors.error.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.block_outlined, size: 18),
      label: Text(_open ? 'Confirmar rechazo' : 'Rechazar pedido'),
    );
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.fastOutSlowIn,
      alignment: Alignment.topCenter,
      child: !_open
          ? button
          : DetailSection(
              title: 'Rechazar',
              icon: Icons.block_outlined,
              tone: colors.error,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthField(
                    label: 'Motivo',
                    hint: 'Lo verá quien hizo el pedido',
                    controller: widget.reason,
                    maxLength: FieldLimits.reason,
                    errorText: widget.errorText,
                    shakeCount: widget.shakeCount,
                  ),
                  const SizedBox(height: 12),
                  button,
                ],
              ),
            ),
    );
  }
}
