import 'package:flutter/material.dart';

import '../../../../core/date_format.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/row_menu_button.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_icons.dart';
import '../../../../theme/app_palette.dart';
import '../../data/inventory_models.dart';
import 'inventory_list_values.dart';

class InventoryTile extends StatelessWidget {
  const InventoryTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });
  final InventoryItem item;
  final VoidCallback onTap, onDelete;
  static const warningDays = inventoryWarningDays;
  static (String, PillTone) expiryOf(InventoryItem item, {DateTime? today}) =>
      inventoryExpiry(item, today: today);
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Editar insumo, lote ${item.lot}',
    child: GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(AppIcons.medication, size: 27),
          ),
          const SizedBox(width: 12),
          Expanded(child: _InventoryDescription(item: item)),
          const SizedBox(width: 4),
          _InventoryActions(item: item, onEdit: onTap, onDelete: onDelete),
        ],
      ),
    ),
  );
}

class _InventoryDescription extends StatelessWidget {
  const _InventoryDescription({required this.item});
  final InventoryItem item;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        item.name,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 3),
      Text(
        item.quantity == 0
            ? 'Sin existencias'
            : '${item.quantity} ${item.quantity == 1 ? 'unidad' : 'unidades'}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 3),
      Text(
        'Lote ${item.lot} · Vence ${formatDay(item.expirationDate, relative: false)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 6),
      _InventoryFlags(item: item),
    ],
  );
}

class _InventoryFlags extends StatelessWidget {
  const _InventoryFlags({required this.item});
  final InventoryItem item;
  @override
  Widget build(BuildContext context) {
    final (expiry, tone) = inventoryExpiry(item);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (tone != PillTone.positive) StatusPill(label: expiry, tone: tone),
        if (item.requiresColdChain) const _ColdChainFlag(),
        if (item.saleType != SaleType.overTheCounter)
          Text(
            item.saleType.label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (item.dangerousGoods)
          Text(
            'Mercancía peligrosa · No vuela',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    );
  }
}

class _ColdChainFlag extends StatelessWidget {
  const _ColdChainFlag();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: context.palette.warning.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      'Cadena de frío',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: context.palette.warning,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _InventoryActions extends StatelessWidget {
  const _InventoryActions({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });
  final InventoryItem item;
  final VoidCallback onEdit, onDelete;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      RowMenuButton(
        icon: AppIcons.more,
        tooltip: 'Opciones del lote ${item.lot}',
        actions: [
          RowMenuAction(
            label: 'Editar insumo',
            icon: AppIcons.edit,
            onSelected: onEdit,
          ),
          RowMenuAction(
            label: 'Eliminar',
            icon: AppIcons.trash,
            destructive: true,
            onSelected: onDelete,
          ),
        ],
      ),
      Icon(
        AppIcons.next,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ],
  );
}
