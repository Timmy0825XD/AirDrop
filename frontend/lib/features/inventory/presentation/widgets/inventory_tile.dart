import 'package:flutter/material.dart';

import '../../../../core/date_format.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/row_menu_button.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_icons.dart';
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
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ItemHeader(item: item, onDelete: onDelete),
        const SizedBox(height: 8),
        _ItemInfo(item: item),
        const SizedBox(height: 12),
        const Divider(height: 1),
        TextButton(
          onPressed: onTap,
          child: const Row(
            children: [
              Icon(AppIcons.edit, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Editar insumo')),
              Icon(AppIcons.next, size: 20),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ItemHeader extends StatelessWidget {
  const _ItemHeader({required this.item, required this.onDelete});
  final InventoryItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Icon(
          AppIcons.medication,
          size: 24,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      RowMenuButton(
        icon: AppIcons.more,
        tooltip: 'Opciones del lote ${item.lot}',
        actions: [
          RowMenuAction(
            label: 'Eliminar',
            icon: AppIcons.trash,
            destructive: true,
            onSelected: onDelete,
          ),
        ],
      ),
    ],
  );
}

class _ItemInfo extends StatelessWidget {
  const _ItemInfo({required this.item});
  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, tone) = inventoryExpiry(item);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.quantity == 0
              ? 'Sin existencias'
              : '${item.quantity} ${item.quantity == 1 ? 'unidad' : 'unidades'}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        StatusPill(label: label, tone: tone),
        const SizedBox(height: 10),
        Text('Lote ${item.lot}', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          'Vence ${formatDay(item.expirationDate, relative: false)}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(item.saleType.label, style: theme.textTheme.bodySmall),
        if (item.requiresColdChain)
          const _ItemNote(icon: AppIcons.coldChain, label: 'Cadena de frío'),
        if (item.dangerousGoods)
          const _ItemNote(
            icon: AppIcons.warning,
            label: 'Mercancía peligrosa · No vuela',
          ),
      ],
    );
  }
}

class _ItemNote extends StatelessWidget {
  const _ItemNote({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}
