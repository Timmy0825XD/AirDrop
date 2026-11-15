import 'package:flutter/material.dart';

import '../../../../../core/date_format.dart';
import '../../../../../core/widgets/list_padding.dart';
import '../../../../../core/widgets/warning_banner.dart';
import '../../../data/order_models.dart';
import 'medication_tile.dart';

/// Los medicamentos que pasaron el filtro. Con [stale] la lista no se pudo
/// actualizar: arriba dice que es la última conocida, de qué hora
/// ([readAt]) y deja reintentar (RNF-17).
class MedicationList extends StatelessWidget {
  const MedicationList({
    super.key,
    required this.offers,
    required this.onOpen,
    this.stale = false,
    this.readAt,
    this.onRetry,
  });

  final List<CatalogOffer> offers;
  final ValueChanged<CatalogOffer> onOpen;
  final bool stale;
  final DateTime? readAt;
  final VoidCallback? onRetry;

  /// "Sin conexión. Esta es la última lista, de las 9:50 a. m."
  static String staleMessage(DateTime? readAt) => readAt == null
      ? 'Sin conexión. Esta es la última lista que se cargó.'
      : 'Sin conexión. Esta es la última lista, de las '
            '${formatClock(readAt)}.';

  @override
  Widget build(BuildContext context) {
    final head = stale ? 1 : 0;
    return ListView.separated(
      padding: listPadding(context, top: 8),
      itemCount: offers.length + head,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i < head) return _notice();
        final offer = offers[i - head];
        return MedicationTile(offer: offer, onTap: () => onOpen(offer));
      },
    );
  }

  Widget _notice() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      WarningBanner(
        message: staleMessage(readAt),
        icon: Icons.cloud_off_rounded,
      ),
      TextButton(onPressed: onRetry, child: const Text('Reintentar')),
    ],
  );
}
