import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/validators.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/form_bottom_sheet.dart';
import '../../../auth/presentation/widgets/auth_date_field.dart';
import '../../../auth/presentation/widgets/auth_field.dart';

/// Motivo y, si aplica, fecha estimada de un periodo de taller.
typedef MaintenanceInput = ({String reason, String estimatedEndDate});

/// Pide el motivo (y la fecha) en una hoja inferior. Los dos estados de
/// Nest (CU-16, CU-17):
///
/// - Con [withDate]: **mantenimiento**, temporal. Motivo y fecha estimada
///   obligatorios; va por `POST /fleet/drones/:id/maintenance`.
/// - Sin [withDate]: **fuera de servicio**, indefinido. Solo el motivo,
///   obligatorio; va por `PATCH .../status` y Nest no guarda fecha.
///
/// Devuelve `null` si se cierra sin guardar.
Future<MaintenanceInput?> showMaintenanceSheet(
  BuildContext context, {
  required bool withDate,
  String initialReason = '',
}) {
  return showAppSheet<MaintenanceInput>(
    context,
    builder: (_) =>
        MaintenanceSheet(withDate: withDate, initialReason: initialReason),
  );
}

/// Los avisos del formulario; sin [tried] (antes de guardar) no hay
/// ninguno. El motivo siempre es obligatorio; la fecha, con [withDate].
({String? reason, String? date}) maintenanceErrors(
  String reason,
  String? date,
  bool withDate, {
  required bool tried,
}) => !tried
    ? (reason: null, date: null)
    : (
        reason: Validators.reason(reason, required: true),
        date: withDate && date == null ? 'Elige la fecha estimada.' : null,
      );

class MaintenanceSheet extends StatefulWidget {
  const MaintenanceSheet({
    super.key,
    required this.withDate,
    this.initialReason = '',
  });

  final bool withDate;
  final String initialReason;

  @override
  State<MaintenanceSheet> createState() => _MaintenanceSheetState();
}

class _MaintenanceSheetState extends State<MaintenanceSheet> {
  late final _reason = TextEditingController(text: widget.initialReason);
  String? _date;
  bool _tried = false;
  int _shakeCount = 0;

  // Se calculan con lo que hay: elegir la fecha borra su aviso solo.
  ({String? reason, String? date}) get _errors =>
      maintenanceErrors(_reason.text, _date, widget.withDate, tried: _tried);

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
    final withDate = widget.withDate;
    return FormBottomSheet(
      title: withDate ? 'Enviar a mantenimiento' : 'Dejar fuera de servicio',
      subtitle: withDate
          ? 'Vuelve a la flota cuando lo marques disponible.'
          : 'Sin fecha de regreso.',
      saveLabel: withDate ? 'Enviar' : 'Dejar fuera',
      onSave: _save,
      children: [
        _MaintenanceFields(
          reason: _reason,
          date: _date,
          withDate: withDate,
          errors: _errors,
          shakeCount: _shakeCount,
          onPickDate: _pickDate,
        ),
      ],
    );
  }
}

/// El motivo y, en mantenimiento, la fecha estimada, con sus errores.
class _MaintenanceFields extends StatelessWidget {
  const _MaintenanceFields({
    required this.reason,
    required this.date,
    required this.withDate,
    required this.errors,
    required this.shakeCount,
    required this.onPickDate,
  });

  final TextEditingController reason;
  final String? date;
  final bool withDate;
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
        if (withDate) ...[
          const SizedBox(height: 16),
          AuthDateField(
            label: 'Fecha estimada',
            value: date,
            hint: 'Elige la fecha',
            errorText: errors.date,
            shakeCount: shakeCount,
            onTap: onPickDate,
          ),
        ],
      ],
    );
  }
}
