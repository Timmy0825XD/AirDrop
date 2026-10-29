import 'package:flutter/material.dart';

import '../../../../../core/widgets/choice_pill.dart';
import '../../../../../core/widgets/detail_section.dart';
import '../../../../auth/presentation/widgets/auth_morph_button.dart';

const _authorizeNote =
    'Se reserva el dron y la ruta. El vuelo arranca cuando confirmes la carga.';

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
    required this.blockedNote,
    required this.busy,
    required this.loading,
    required this.onAuthorize,
  });

  final bool needsPrescriptionCheck;
  final bool prescriptionVerified;
  final ValueChanged<bool> onVerifiedChanged;

  /// `null` cuando la imagen no se puede ver (planes y traslados).
  final VoidCallback? onViewPrescription;

  /// Por qué todavía no se autoriza (fecha futura, fuera de la ventana de
  /// 2 horas o franja cerrada); `null` si se puede.
  final String? blockedNote;

  /// [busy]: hay alguna acción en curso y los botones se apagan.
  /// [loading]: la acción en curso es esta y el botón se vuelve el dron.
  final bool busy;
  final bool loading;
  final VoidCallback onAuthorize;

  @override
  Widget build(BuildContext context) {
    final checked = !needsPrescriptionCheck || prescriptionVerified;
    final ready = blockedNote == null && checked;
    return DetailSection(
      title: 'Autorizar salida',
      icon: Icons.verified_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            blockedNote ?? _authorizeNote,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (needsPrescriptionCheck) _PrescriptionCheck(section: this),
          const SizedBox(height: 14),
          AuthMorphButton(
            label: 'Autorizar',
            loadingLabel: 'Autorizando el pedido',
            isLoading: loading,
            onPressed: ready && !busy ? onAuthorize : null,
          ),
        ],
      ),
    );
  }
}

/// "Ver fórmula" (si la imagen se puede bajar) y el chip "Verifiqué la
/// fórmula" que enciende el botón.
class _PrescriptionCheck extends StatelessWidget {
  const _PrescriptionCheck({required this.section});

  final AuthorizeSection section;

  @override
  Widget build(BuildContext context) {
    final s = section;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (s.onViewPrescription != null)
            OutlinedButton.icon(
              onPressed: s.busy ? null : s.onViewPrescription,
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('Ver fórmula'),
            ),
          ChoicePill(
            label: 'Verifiqué la fórmula',
            selected: s.prescriptionVerified,
            showCheck: true,
            filled: false,
            onTap: () {
              if (!s.busy) s.onVerifiedChanged(!s.prescriptionVerified);
            },
          ),
        ],
      ),
    );
  }
}
