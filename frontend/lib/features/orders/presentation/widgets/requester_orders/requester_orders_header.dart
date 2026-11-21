import 'package:flutter/material.dart';

import '../../../../../theme/app_icons.dart';

class RequesterOrdersHeader extends StatelessWidget {
  const RequesterOrdersHeader({
    super.key,
    required this.onlyOpen,
    required this.onFilter,
    required this.searching,
    required this.onSearch,
    required this.search,
    required this.onQuery,
  });
  final bool onlyOpen;
  final ValueChanged<bool> onFilter;
  final bool searching;
  final VoidCallback onSearch;
  final TextEditingController search;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: _OrdersTitle()),
            IconButton(
              onPressed: onSearch,
              tooltip: searching ? 'Cerrar búsqueda' : 'Buscar pedido',
              icon: Icon(searching ? AppIcons.close : AppIcons.search),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _OrderFilters(onlyOpen: onlyOpen, onFilter: onFilter),
        if (searching) ...[
          const SizedBox(height: 14),
          TextField(
            controller: search,
            autofocus: true,
            onChanged: onQuery,
            decoration: const InputDecoration(
              hintText: 'Buscar medicamento',
              prefixIcon: Icon(AppIcons.search),
            ),
          ),
        ],
      ],
    ),
  );
}

class _OrdersTitle extends StatelessWidget {
  const _OrdersTitle();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Mis pedidos',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Sigue tus entregas.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _OrderFilters extends StatelessWidget {
  const _OrderFilters({required this.onlyOpen, required this.onFilter});
  final bool onlyOpen;
  final ValueChanged<bool> onFilter;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          for (final open in [true, false])
            Expanded(
              child: Semantics(
                selected: open == onlyOpen,
                child: TextButton(
                  onPressed: () => onFilter(open),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: open == onlyOpen
                        ? colors.primary
                        : Colors.transparent,
                    foregroundColor: open == onlyOpen
                        ? colors.onPrimary
                        : colors.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(open ? 'En curso' : 'Historial'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
