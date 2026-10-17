import 'package:flutter/material.dart';

import '../../../../core/widgets/press_scale.dart';
import '../../../../core/widgets/row_action_button.dart';
import '../../../../core/widgets/status_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/tone_tile.dart';
import '../../data/inventory_models.dart';

/// Fila del inventario: nombre, lote, cantidad, tipo de venta y
/// vencimiento, con la cadena de frío marcada en el ícono. A la derecha,
/// si el lote está vencido o por vencer, y "Eliminar". Tocarla abre la
/// edición.
class InventoryTile extends StatelessWidget {
  const InventoryTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final InventoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// Días que se avisan antes del vencimiento.
  static const warningDays = 30;

  /// Vencido, por vencer o vigente, con la fecha de hoy.
  static (String, PillTone) expiryOf(InventoryItem item, {DateTime? today}) {
    final date = DateTime.tryParse(item.expirationDate);
    final now = DateUtils.dateOnly(today ?? DateTime.now());
    if (date == null) return ('Vigente', PillTone.positive);
    if (date.isBefore(now)) return ('Vencido', PillTone.negative);
    if (date.difference(now).inDays <= warningDays) {
      return ('Por vencer', PillTone.attention);
    }
    return ('Vigente', PillTone.positive);
  }

  @override
  Widget build(BuildContext context) {
    final (label, tone) = expiryOf(item);
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: StatusCard(
          leading: _ItemIcon(coldChain: item.requiresColdChain),
          body: _ItemInfo(item: item),
          status: StatusPill(label: label, tone: tone),
          action: RowActionButton(
            label: 'Eliminar',
            destructive: true,
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }
}

/// El cuadro del ícono: copo de nieve si va en cadena de frío.
class _ItemIcon extends StatelessWidget {
  const _ItemIcon({required this.coldChain});

  final bool coldChain;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tone = coldChain ? colors.tertiary : colors.primary;
    return ToneTile(
      tone: tone,
      child: Icon(
        coldChain ? Icons.ac_unit_rounded : Icons.medication_outlined,
        color: tone,
        size: 22,
        semanticLabel: coldChain ? 'Cadena de frío' : null,
      ),
    );
  }
}

class _ItemInfo extends StatelessWidget {
  const _ItemInfo({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Lote ${item.lot} · ${item.quantity} und.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          [
            item.saleType.label,
            if (item.requiresColdChain) 'Cadena de frío',
            'Vence ${item.expirationDate}',
          ].join(' · '),
          style: muted,
        ),
      ],
    );
  }
}
