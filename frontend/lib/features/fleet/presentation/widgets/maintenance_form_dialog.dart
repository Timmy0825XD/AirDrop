import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/validators.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Motivo y fecha estimada escritos en el diálogo.
typedef MaintenanceInput = ({String reason, String estimatedEndDate});

/// Pide motivo y fecha estimada de un mantenimiento.
///
/// Con [mandatory] en `true` son obligatorios: es la vía de
/// `POST /fleet/drones/:id/maintenance`, que deja el dron fuera de
/// servicio. En `false` ambos son opcionales, como el body de
/// `PATCH /fleet/drones/:id/status` (si no llegan, Nest conserva los que
/// ya tenía el dron). Devuelve `null` si se cancela.
Future<MaintenanceInput?> showMaintenanceDialog(
  BuildContext context, {
  required bool mandatory,
  String initialReason = '',
  String initialDate = '',
}) {
  return showDialog<MaintenanceInput>(
    context: context,
    builder: (_) => MaintenanceFormDialog(
      mandatory: mandatory,
      initialReason: initialReason,
      initialDate: initialDate,
    ),
  );
}

class MaintenanceFormDialog extends StatefulWidget {
  const MaintenanceFormDialog({
    super.key,
    required this.mandatory,
    this.initialReason = '',
    this.initialDate = '',
  });

  final bool mandatory;
  final String initialReason;
  final String initialDate;

  @override
  State<MaintenanceFormDialog> createState() => _MaintenanceFormDialogState();
}

class _MaintenanceFormDialogState extends State<MaintenanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _reason = TextEditingController(text: widget.initialReason);
  late final _date = TextEditingController(text: widget.initialDate);

  @override
  void dispose() {
    _reason.dispose();
    _date.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mandatory = widget.mandatory;
    return AlertDialog(
      title: Text(
        mandatory ? 'Registrar mantenimiento' : 'Poner en mantenimiento',
      ),
      content: Form(
        key: _formKey,
        child: _MaintenanceFields(
          reason: _reason,
          date: _date,
          mandatory: mandatory,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(mandatory ? 'Registrar' : 'Guardar'),
        ),
      ],
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      (
        reason: _reason.text.trim(),
        estimatedEndDate: _date.text.trim(),
      ),
    );
  }
}

/// Los dos campos del diálogo. Pinta los controllers y valida con los
/// mismos topes que los DTO de Nest.
class _MaintenanceFields extends StatelessWidget {
  const _MaintenanceFields({
    required this.reason,
    required this.date,
    required this.mandatory,
  });

  final TextEditingController reason;
  final TextEditingController date;
  final bool mandatory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Motivo',
            controller: reason,
            maxLength: FieldLimits.reason,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                Validators.reason(value, required: mandatory),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Fecha estimada',
            controller: date,
            helperText: 'AAAA-MM-DD',
            validator: (value) => _estimatedDate(value, mandatory: mandatory),
          ),
        ],
      ),
    );
  }
}

/// Mismo formato que `RegisterMaintenanceDto`. El copy es el del DTO de
/// Nest (`La fecha estimada debe ser AAAA-MM-DD.`).
String? _estimatedDate(String? value, {required bool mandatory}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return mandatory ? 'Escribe la fecha estimada.' : null;
  }
  if (!FieldLimits.isoDateRegex.hasMatch(text)) {
    return 'La fecha estimada debe ser AAAA-MM-DD.';
  }
  if (DateTime.tryParse(text) == null) {
    return 'La fecha estimada no es válida.';
  }
  return null;
}
