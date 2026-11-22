import 'package:flutter/material.dart';
import '../../../../../theme/app_icons.dart';

class HubTransferPreview extends StatelessWidget {
  const HubTransferPreview({super.key, required this.map});
  final Widget? map;
  @override
  Widget build(BuildContext context) => map == null
      ? const SizedBox.shrink()
      : ExpansionTile(
          tilePadding: EdgeInsets.zero,
          leading: const Icon(AppIcons.destination),
          title: const Text('Ver traslado en el mapa'),
          children: [map!],
        );
}
