import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api_exception.dart';
import '../../../../core/widgets/auto_refresh.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../home/presentation/widgets/section_header.dart';

/// El andamiaje de una bandeja del despachador (cola, programados,
/// pendiente de carga, vuelos en curso): encabezado curvo con cuántas hay,
/// la lista que entra en cascada, deslizar para recargar, el aviso de lista
/// vacía o el error de Nest, y el refresco cada 10 s.
class OrderTray<T> extends StatelessWidget {
  const OrderTray({
    super.key,
    required this.title,
    required this.idleSubtitle,
    required this.countLabel,
    required this.rows,
    required this.onRefresh,
    required this.emptyIcon,
    required this.emptyText,
    required this.keyOf,
    required this.itemBuilder,
  });

  final String title;

  /// El subtítulo mientras la lista carga o si falló.
  final String idleSubtitle;
  final String Function(int count) countLabel;
  final AsyncValue<List<T>> rows;
  final VoidCallback onRefresh;
  final IconData emptyIcon;
  final String emptyText;
  final String Function(T row) keyOf;
  final Widget Function(BuildContext context, T row) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final count = rows.asData?.value.length;
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: title,
            subtitle: count == null ? idleSubtitle : countLabel(count),
            onBack: () => context.go('/home'),
          ),
          Expanded(
            child: AutoRefresh(
              onTick: onRefresh,
              child: switch (rows) {
                AsyncData(:final value) => _list(value),
                AsyncError(:final error) => MessageView(
                  icon: Icons.cloud_off_rounded,
                  message: ApiException.messageOf(error),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(List<T> items) {
    if (items.isEmpty) return MessageView(icon: emptyIcon, message: emptyText);
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => RiseIn(
          key: ValueKey(keyOf(items[i])),
          delay: RiseIn.stagger(i),
          child: itemBuilder(context, items[i]),
        ),
      ),
    );
  }
}
