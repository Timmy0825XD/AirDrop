import 'package:flutter/material.dart';

import '../requester_order/requester_order_values.dart';

class EmergencyReview extends StatelessWidget {
  const EmergencyReview({
    super.key,
    required this.values,
    required this.onEdit,
  });
  final RequesterOrderValues values;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Revisa tu urgencia',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            for (final row in _reviewRows(values)) _ReviewLine(label: row.$1, value: row.$2),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => onEdit(0),
              child: const Text('Editar situación'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => onEdit(1),
              child: const Text('Editar medicamento'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Listo'),
            ),
          ],
        ),
      ),
    );
  }
}

List<(String, String)> _reviewRows(RequesterOrderValues values) {
  final d = values.triage;
  return [
    ('Paciente', d.forSomeoneElse ? d.patientName.text : 'Para mí'),
    ('Grupo de edad', d.group?.label ?? 'Por indicar'),
    if (d.group?.mayBePregnant == true) ('Embarazo', d.pregnant == true ? 'Sí' : 'No'),
    ('Signos de alarma', d.hasRedFlag ? d.redFlags.map((f) => f.label).join(', ') : 'Ninguno'),
    ('Síntomas', d.symptoms.map((s) => s.label).join(', ')),
    ('Desde cuándo', d.onset?.label ?? 'Por indicar'),
    ('Intensidad', d.severity?.label ?? 'Por indicar'),
    ('Medicamento', values.offer?.name ?? 'Por seleccionar'),
    ('Cantidad', '1 unidad'),
    ('Alergias', d.hasAllergies == true ? d.allergies.text : 'Ninguna'),
    if (values.needsPrescription) ('Fórmula', '${values.prescriptions.length} adjunto(s)'),
    if (values.reference != null) ('Referencia', values.reference!),
    if (values.description.text.trim().isNotEmpty) ('Nota', values.description.text.trim()),
  ];
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}
