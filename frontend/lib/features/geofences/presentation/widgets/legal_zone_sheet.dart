import 'package:flutter/material.dart';

import '../../../../core/widgets/app_sheet.dart';
import '../../data/legal_zone_models.dart';

/// El detalle de una zona legal: qué hace, la norma que la respalda y de
/// dónde sale el dato. No tiene botones: el operador no la cambia.
Future<void> showLegalZoneSheet(BuildContext context, LegalZone zone) {
  return showAppSheet<void>(
    context,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final muted = theme.colorScheme.onSurfaceVariant;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(zone.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(zone.kind.label, style: TextStyle(color: muted)),
              const SizedBox(height: 16),
              Text(
                'Ninguna ruta la cruza: el motor la rodea. Viene con el '
                'escenario y no se edita desde la app.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text('Norma', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(zone.legalBasis, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text(
                'Fuente: ${zone.source}',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      );
    },
  );
}
