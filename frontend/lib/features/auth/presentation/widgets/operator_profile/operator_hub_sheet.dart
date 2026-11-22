import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_sheet.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../hubs/data/hub_models.dart';
import '../../../../hubs/presentation/widgets/hub_detail_content.dart';

/// Consulta la central asignada sin abrir rutas de administración.
Future<void> showOperatorHubSheet(
  BuildContext context,
  Hub hub, {
  required VoidCallback onFleet,
}) => showAppSheet<void>(
  context,
  builder: (sheet) => FractionallySizedBox(
    heightFactor: .86,
    child: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tu central',
                  style: Theme.of(sheet).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.pop(sheet),
                icon: const Icon(AppIcons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          HubDetailContent(hub: hub),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(sheet);
              onFleet();
            },
            icon: const Icon(AppIcons.forward),
            label: const Text('Ver flota de esta central'),
          ),
        ],
      ),
    ),
  ),
);
