import 'package:flutter/material.dart';
import '../../../../../core/widgets/form_section.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../hubs/data/hub_models.dart';

class HubRequestDestination extends StatelessWidget {
  const HubRequestDestination({super.key, required this.hub});
  final Hub? hub;
  @override
  Widget build(BuildContext context) => FormSection(
    title: 'Destino',
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.hub),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu central',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(hub?.name ?? 'Tu central asignada'),
                if (hub != null)
                  Text(
                    hub!.address,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}
