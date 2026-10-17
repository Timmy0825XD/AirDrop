import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/validators.dart';
import '../../../../core/widgets/form_bottom_sheet.dart';
import '../../../auth/presentation/widgets/auth_date_field.dart';
import '../../../auth/presentation/widgets/auth_field.dart';

/// Motivo y fecha estimada de un mantenimiento.
typedef MaintenanceInput = ({String reason, String estimatedEndDate});

/// Pide motivo y fecha estimada en una hoja inferior. La fecha se elige en
/// el calendario (antes se escribía a mano en AAAA-MM-DD).
///
/// Con [mandatory] en `true` los dos son obligatorios: es la vía de
/// `POST /fleet/drones/:id/maintenance`, que deja el dron fuera de
/// servicio. En `false` son opcionales, como el body de
/// `PATCH /fleet/drones/:id/status` (si no llegan, Nest conserva los que
/// ya tenía el dron). Devuelve `null` si se cierra sin guardar.
Future<MaintenanceInput?> showMaintenanceSheet(
  BuildContext context, {
  required bool mandatory,
  String initialReason = '',
  String initialDate = '',
}) {
  return showModalBottomSheet<MaintenanceInput>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => MaintenanceSheet(
      mandatory: mandatory,
      initialReason: initialReason,
      initialDate: initialDate,
    ),
  );
}

/// Los avisos del formulario; sin [tried] (antes de guardar) no hay
/// ninguno. Con [mandatory], motivo y fecha son obligatorios.
({String? reason, String? date}) maintenanceErrors(
  String reason,
  String? date,
  bool mandatory, {
  required bool tried,
}) => !tried
    ? (reason: null, date: null)
    : (
        reason: Validators.reason(reason, required: mandatory),
        date: mandatory && date == null ? 'Elige la fecha estimada.' : null,
      );

class MaintenanceSheet extends StatefulWidget {
  const MaintenanceSheet({
    super.key,
    required this.mandatory,
    this.initialReason = '',
    this.initialDate = '',
  });

  final bool mandatory;
  final String initialReason;
  final String initialDate;

  @override
  State<MaintenanceSheet> createState() => _MaintenanceSheetState();
}

class _MaintenanceSheetState extends State<MaintenanceSheet> {
  late final _reason = TextEditingController(text: widget.initialReason);
  late String? _date = widget.initialDate.isEmpty ? null : widget.initialDate;
  bool _tried = false;
  int _shakeCount = 0;

  // Se calculan con lo que hay: elegir la fecha borra su aviso solo.
  ({String? reason, String? date}) get _errors =>
      maintenanceErrors(_reason.text, _date, widget.mandatory, tried: _tried);

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await pickFutureDate(context, current: _date);
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    setState(() => _tried = true);
    final errors = _errors;
    if (errors.reason != null || errors.date != null) {
      setState(() => _shakeCount++);
      return;
    }
    Navigator.pop(context, (
      reason: _reason.text.trim(),
      estimatedEndDate: _date ?? '',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mandatory = widget.mandatory;
    return FormBottomSheet(
      title: mandatory ? 'Registrar mantenimiento' : 'Poner en mantenimiento',
      subtitle: mandatory
          ? 'El dron queda fuera de servicio hasta que lo marques disponible.'
          : 'Motivo y fecha son opcionales.',
      saveLabel: mandatory ? 'Registrar' : 'Guardar',
      onSave: _save,
      children: [
        _MaintenanceFields(
          reason: _reason,
          date: _date,
          mandatory: mandatory,
          errors: _errors,
          shakeCount: _shakeCount,
          onPickDate: _pickDate,
        ),
      ],
    );
  }
}

/// El motivo y la fecha estimada, con sus errores.
class _MaintenanceFields extends StatelessWidget {
  const _MaintenanceFields({
    required this.reason,
    required this.date,
    required this.mandatory,
    required this.errors,
    required this.shakeCount,
    required this.onPickDate,
  });

  final TextEditingController reason;
  final String? date;
  final bool mandatory;
  final ({String? reason, String? date}) errors;
  final int shakeCount;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthField(
          label: 'Motivo',
          hint: 'Cambio de hélices',
          controller: reason,
          maxLength: FieldLimits.reason,
          errorText: errors.reason,
          shakeCount: shakeCount,
        ),
        const SizedBox(height: 16),
        AuthDateField(
          label: 'Fecha estimada',
          value: date,
          hint: mandatory ? 'Elige la fecha' : 'Opcional',
          errorText: errors.date,
          shakeCount: shakeCount,
          onTap: onPickDate,
        ),
      ],
    );
  }
}
