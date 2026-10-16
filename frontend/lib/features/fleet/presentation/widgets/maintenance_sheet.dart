import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/validators.dart';
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
  String? _reasonError;
  String? _dateError;
  int _shakeCount = 0;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await pickIsoDate(
      context,
      current: _date,
      first: today,
      last: today.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final reasonError = Validators.reason(
      _reason.text,
      required: widget.mandatory,
    );
    final dateError = widget.mandatory && _date == null
        ? 'Elige la fecha estimada.'
        : null;
    setState(() {
      _reasonError = reasonError;
      _dateError = dateError;
      if (reasonError != null || dateError != null) _shakeCount++;
    });
    if (reasonError != null || dateError != null) return;
    Navigator.pop(context, (
      reason: _reason.text.trim(),
      estimatedEndDate: _date ?? '',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mandatory = widget.mandatory;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            mandatory ? 'Registrar mantenimiento' : 'Poner en mantenimiento',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            mandatory
                ? 'El dron queda fuera de servicio hasta que lo marques disponible.'
                : 'Motivo y fecha son opcionales.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          AuthField(
            label: 'Motivo',
            hint: 'Cambio de hélices',
            controller: _reason,
            maxLength: FieldLimits.reason,
            errorText: _reasonError,
            shakeCount: _shakeCount,
          ),
          const SizedBox(height: 16),
          AuthDateField(
            label: 'Fecha estimada',
            value: _date,
            hint: mandatory ? 'Elige la fecha' : 'Opcional',
            errorText: _dateError,
            shakeCount: _shakeCount,
            onTap: _pickDate,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(mandatory ? 'Registrar' : 'Guardar'),
          ),
        ],
      ),
    );
  }
}
