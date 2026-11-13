import 'package:flutter/material.dart';

import '../../../../../core/widgets/detail_section.dart';
import '../../../../../theme/app_palette.dart';
import '../../../data/order_models.dart';

/// Lo que el solicitante contó de la urgencia (RF-41) y para quién es
/// (RF-42), arriba del detalle: el signo de alarma en rojo, el paciente,
/// qué siente y sus alergias. Así el despachador decide sin leer un texto
/// libre.
class TriageCard extends StatelessWidget {
  const TriageCard({super.key, required this.order});

  final Order order;

  /// Hay algo que mostrar: tamizaje o persona a cargo.
  static bool appliesTo(Order order) =>
      order.triage != null || order.patient != null;

  @override
  Widget build(BuildContext context) {
    final triage = order.triage;
    final patient = order.patient;
    return DetailSection(
      title: 'Tamizaje',
      icon: Icons.medical_information_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (triage != null && triage.hasRedFlag) ...[
            AlarmLine(flags: triage.redFlags),
            const SizedBox(height: 10),
          ],
          if (patient != null)
            DetailLine(
              label: 'Paciente',
              value:
                  '${patient.fullName} · ${patient.relation.label} del '
                  'titular · ${patient.documentType.label} '
                  '${patient.documentNumber}',
            ),
          if (triage != null) ...[
            DetailLine(label: 'Edad', value: _ageLine(triage)),
            DetailLine(
              label: 'Síntomas',
              value: triage.symptoms.map((s) => s.label).join(', '),
            ),
            DetailLine(label: 'Desde', value: triage.onset.label),
            DetailLine(label: 'Intensidad', value: triage.severity.label),
            DetailLine(label: 'Alergias', value: order.allergies ?? 'Ninguna'),
          ],
        ],
      ),
    );
  }

  static String _ageLine(OrderTriage triage) => switch (triage.pregnant) {
    true => '${triage.patientGroup.label} · embarazada',
    _ => triage.patientGroup.label,
  };
}

/// Los signos de alarma, en rojo: la urgencia va primero en la cola.
class AlarmLine extends StatelessWidget {
  const AlarmLine({super.key, required this.flags});

  final List<RedFlag> flags;

  @override
  Widget build(BuildContext context) {
    final danger = context.palette.danger;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_rounded, color: danger, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Signo de alarma: ${flags.map((f) => f.label).join(', ')}.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: danger),
            ),
          ),
        ],
      ),
    );
  }
}
