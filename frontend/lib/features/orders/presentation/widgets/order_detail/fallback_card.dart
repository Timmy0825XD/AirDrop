import 'package:flutter/material.dart';

import '../../../../../core/widgets/detail_section.dart';
import '../../../../../theme/app_palette.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';

/// HU-24 y CU-05: qué pasó cuando ningún dron pudo salir. Lo ven quien
/// pidió y quien despacha: a qué central pasó, dónde más hay insumo (para
/// el traslado convencional) o cuándo se reintenta. El motivo es el de
/// Nest, tal cual.
class FallbackCard extends StatelessWidget {
  const FallbackCard({super.key, required this.fallback});

  final OrderFallback fallback;

  String get _title => switch (fallback.kind) {
    FallbackKind.hub => 'Lo atiende otra central',
    FallbackKind.conventional => 'Este pedido no puede ir en dron',
    FallbackKind.retry => 'Estamos buscando un dron',
  };

  String? get _lead => switch (fallback.kind) {
    FallbackKind.hub =>
      fallback.newHub == null
          ? null
          : 'Tu pedido lo atiende ahora ${fallback.newHub!.name}.',
    FallbackKind.conventional =>
      'Puedes conseguirlo en estas centrales con traslado convencional:',
    FallbackKind.retry =>
      fallback.retryAfter == null
          ? 'Se reintenta solo cada 15 minutos.'
          : 'Próximo intento a las ${formatClock(fallback.retryAfter!)}.',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = fallback.kind == FallbackKind.retry
        ? const <FallbackOption>[]
        : fallback.options;
    return DetailSection(
      title: _title,
      icon: Icons.alt_route_rounded,
      tone: context.palette.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (fallback.reason case final reason?)
            Text(reason, style: theme.textTheme.bodyMedium),
          if (_lead case final lead?) ...[
            const SizedBox(height: 8),
            Text(lead, style: theme.textTheme.bodyMedium),
          ],
          for (final option in options) ...[
            const SizedBox(height: 10),
            FallbackOptionTile(option: option),
          ],
        ],
      ),
    );
  }
}

/// Una central alternativa: nombre, distancia, dirección y contacto (se
/// puede copiar).
class FallbackOptionTile extends StatelessWidget {
  const FallbackOptionTile({super.key, required this.option});

  final FallbackOption option;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final distance = option.distanceKm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          distance == null
              ? option.name
              : '${option.name} · ${formatKm(distance)}',
          style: theme.textTheme.titleSmall,
        ),
        if (option.address.isNotEmpty) Text(option.address, style: muted),
        SelectableText(
          [
            if (option.contactPhone.isNotEmpty) option.contactPhone,
            ?option.contactEmail,
          ].join(' · '),
          style: muted,
        ),
      ],
    );
  }
}
