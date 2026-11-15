import 'package:flutter/material.dart';

import '../../../../../core/widgets/warning_banner.dart';
import '../../../data/order_models.dart';
import '../order_detail/fallback_card.dart';

/// Sin cobertura (RU-02, RF-18): por qué no se entrega con dron ahí (el
/// texto de Nest) y las centrales donde recoger el medicamento, con su
/// dirección y su teléfono. No se crea ningún pedido.
class GroundAlternativeCard extends StatelessWidget {
  const GroundAlternativeCard({super.key, required this.coverage});

  final CoverageResult coverage;

  static const _fallbackMessage =
      'Aquí no se entrega con dron. Puedes recoger el medicamento en una '
      'central cercana.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = coverage.alternatives;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WarningBanner(
          message: coverage.message ?? _fallbackMessage,
          icon: Icons.location_off_rounded,
        ),
        if (options.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Dónde recogerlo', style: theme.textTheme.titleSmall),
          for (final option in options) ...[
            const SizedBox(height: 10),
            FallbackOptionTile(option: option),
          ],
        ],
      ],
    );
  }
}
