import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/validators.dart';
import '../../../../../core/widgets/app_sheet.dart';
import '../../../../../core/widgets/choice_pill.dart';
import '../../../../../core/widgets/form_bottom_sheet.dart';
import '../../../../auth/presentation/widgets/auth_field.dart';

/// Los motivos de un toque; "Otro" deja escribirlo.
const declineReasons = ['Sin dron disponible', 'Sin personal para cargar'];

/// "No puedo atenderla" (RU-10): pide el motivo, que es opcional, y
/// devuelve lo que se manda a Nest (`''` sin motivo) o `null` si se cierra.
/// La urgencia no se cierra: pasa a la siguiente central.
Future<String?> showDeclineSheet(BuildContext context) {
  return showAppSheet<String>(context, builder: (_) => const DeclineSheet());
}

class DeclineSheet extends StatefulWidget {
  const DeclineSheet({super.key});

  @override
  State<DeclineSheet> createState() => _DeclineSheetState();
}

class _DeclineSheetState extends State<DeclineSheet> {
  final _other = TextEditingController();

  /// El motivo elegido; `null` es "Otro" (lo escrito).
  String? _picked = declineReasons.first;
  String? _error;
  int _shakeCount = 0;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  void _send() {
    final reason = _picked ?? _other.text.trim();
    final error = Validators.reason(reason, required: false);
    if (error != null) {
      setState(() {
        _error = error;
        _shakeCount++;
      });
      return;
    }
    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    return FormBottomSheet(
      title: 'No puedo atenderla',
      subtitle:
          'La urgencia pasa a la siguiente central. No se cierra el pedido.',
      saveLabel: 'Pasarla a otra central',
      onSave: _send,
      children: [
        _ReasonPills(
          picked: _picked,
          onPick: (reason) => setState(() => _picked = reason),
        ),
        if (_picked == null) ...[
          const SizedBox(height: 14),
          AuthField(
            label: 'Motivo',
            hint: 'Opcional',
            controller: _other,
            maxLength: FieldLimits.reason,
            errorText: _error,
            shakeCount: _shakeCount,
          ),
        ],
      ],
    );
  }
}

/// Los motivos rápidos y "Otro".
class _ReasonPills extends StatelessWidget {
  const _ReasonPills({required this.picked, required this.onPick});

  final String? picked;
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final reason in declineReasons)
          ChoicePill(
            label: reason,
            selected: picked == reason,
            showCheck: true,
            onTap: () => onPick(reason),
          ),
        ChoicePill(
          label: 'Otro',
          selected: picked == null,
          showCheck: true,
          onTap: () => onPick(null),
        ),
      ],
    );
  }
}
