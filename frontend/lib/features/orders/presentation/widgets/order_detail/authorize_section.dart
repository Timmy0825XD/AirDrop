import 'package:flutter/material.dart';

import 'detail_section.dart';

/// Autorizar un pedido en `received`: el motor de decisión elige dron y
/// ruta, y el pedido pasa a "Pendiente de carga" (todavía no despega).
///
/// Si el pedido va a una persona y es bajo fórmula, antes hay que revisar
/// la fórmula y marcar "Verifiqué la fórmula"; sin eso el botón no se
/// enciende.
class AuthorizeSection extends StatelessWidget {
  const AuthorizeSection({
    super.key,
    required this.needsPrescriptionCheck,
    required this.prescriptionVerified,
    required this.onVerifiedChanged,
    required this.onViewPrescription,
    required this.notYet,
    required this.busy,
    required this.onAuthorize,
  });

  final bool needsPrescriptionCheck;
  final bool prescriptionVerified;
  final ValueChanged<bool> onVerifiedChanged;

  /// `null` cuando la imagen no se puede ver (planes y traslados).
  final VoidCallback? onViewPrescription;

  /// Programado con fecha futura: todavía no se autoriza.
  final bool notYet;
  final bool busy;
  final VoidCallback onAuthorize;

  @override
  Widget build(BuildContext context) {
    final ready = !notYet && (!needsPrescriptionCheck || prescriptionVerified);
    return DetailSection(
      title: 'Autorizar salida',
      icon: Icons.verified_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            notYet
                ? 'Este pedido programado todavía no llega a su fecha.'
                : 'Se reserva el dron y la ruta. El vuelo arranca cuando '
                      'confirmes la carga.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (needsPrescriptionCheck) _PrescriptionCheck(section: this),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: ready && !busy ? onAuthorize : null,
            child: const Text('Autorizar'),
          ),
        ],
      ),
    );
  }
}

/// "Ver fórmula" (si la imagen se puede bajar) y la casilla "Verifiqué la
/// fórmula" que enciende el botón.
class _PrescriptionCheck extends StatelessWidget {
  const _PrescriptionCheck({required this.section});

  final AuthorizeSection section;

  @override
  Widget build(BuildContext context) {
    final s = section;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.onViewPrescription != null)
          TextButton.icon(
            onPressed: s.busy ? null : s.onViewPrescription,
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Ver fórmula'),
          ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: s.prescriptionVerified,
          onChanged: s.busy ? null : (v) => s.onVerifiedChanged(v ?? false),
          title: const Text('Verifiqué la fórmula'),
        ),
      ],
    );
  }
}
