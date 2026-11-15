import 'package:flutter/material.dart';

import '../../../../../core/widgets/detail_section.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';

/// "0,03 kg" o "1,2 kg": el peso con coma.
String manifestWeight(double kg) =>
    '${kg.toStringAsFixed(kg < 1 ? 2 : 1).replaceAll('.', ',')} kg';

/// "Acetaminofén 500 mg · 1 unidad · lote ACE-N-2601 (vence sáb. 8 ene.)"
String manifestItemLine(ManifestItem item) => [
  ?item.medicationName,
  unitsLabel(item.quantity),
  'lote ${item.lot} (vence ${formatDay(item.expiresOn, relative: false)})',
].join(' · ');

/// El manifiesto de carga del pedido (RF-47), para el despachador: número,
/// dron, de dónde a dónde, qué lleva (lote y vencimiento), peso, frío y
/// quién confirmó. Si reemplazó a otro, lo dice. Nunca lo ve el
/// solicitante (Nest le responde 403).
class ManifestCard extends StatelessWidget {
  const ManifestCard({super.key, required this.manifest});

  final CargoManifest manifest;

  @override
  Widget build(BuildContext context) {
    final m = manifest;
    final theme = Theme.of(context);
    final cold = m.coldRange;
    return DetailSection(
      title: 'Manifiesto ${m.number}',
      icon: Icons.receipt_long_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailLine(label: 'Dron', value: m.droneIdentifier),
          DetailLine(label: 'Sale de', value: m.originName),
          DetailLine(label: 'Llega a', value: m.destination),
          for (final item in m.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                manifestItemLine(item),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          if (m.payloadKg case final kg?)
            DetailLine(label: 'Peso', value: manifestWeight(kg)),
          if (cold != null) DetailLine(label: 'Frío', value: cold),
          DetailLine(label: 'Autorizó', value: m.authorizedBy),
          if (m.issuedAt case final at?)
            DetailLine(label: 'Emitido', value: formatDateTime(at)),
          for (final old in m.previous)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Reemplaza a ${old.number}'
                '${old.voidReason == null ? '' : ' (anulado: ${old.voidReason})'}',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
