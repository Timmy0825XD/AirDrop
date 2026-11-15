import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/clock/sim_clock.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/skeleton.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/medications/medication_filters.dart';
import 'widgets/medications/medication_list.dart';
import 'widgets/medications/medication_rules.dart';
import 'widgets/medications/medication_sheet.dart';

/// Medicamentos disponibles (RU-33, RF-54, CU-49): lo que el solicitante
/// puede pedir por dron, sobre el mismo catálogo de la urgencia. Dice el
/// nombre, si exige fórmula, si viaja en frío y si hay, en palabras. Desde
/// un medicamento se empieza la urgencia con ese ítem ya elegido. Sin
/// conexión queda la última lista conocida, con su hora (RNF-17).
class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  final _search = TextEditingController();
  var _filter = const MedicationFilter();

  /// La hora (simulada) de la última lista que sí llegó.
  DateTime? _readAt;

  @override
  void initState() {
    super.initState();
    // Una lista que ya estaba cargada se vuelve a pedir al abrir.
    if (ref.read(catalogProvider).hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
    }
  }

  void _reload() {
    if (mounted) ref.invalidate(catalogProvider);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clear() {
    _search.clear();
    setState(() => _filter = const MedicationFilter());
  }

  Future<void> _open(CatalogOffer offer) async {
    final order = await showMedicationSheet(context, offer);
    if (order && mounted) context.push('/orders/emergency', extra: offer);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(catalogProvider, (_, next) {
      if (next is AsyncData) setState(() => _readAt = simClock.now());
    });
    final catalog = ref.watch(catalogProvider);
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Medicamentos',
            subtitle: 'Lo que puedes pedir por dron',
            onBack: () => SectionHeader.backOrHome(context),
            bottom: MedicationFilters(
              filter: _filter,
              controller: _search,
              onChanged: (next) => setState(() => _filter = next),
            ),
          ),
          Expanded(
            child: switch (catalog) {
              AsyncValue(hasValue: true, :final value?) => _list(
                value,
                stale: catalog.hasError,
              ),
              AsyncError(:final error) => MessageView.error(
                message: ApiException.messageOf(error),
                action: OutlinedButton(
                  onPressed: _reload,
                  child: const Text('Reintentar'),
                ),
              ),
              _ => const SkeletonList(),
            },
          ),
        ],
      ),
    );
  }

  Widget _list(List<CatalogOffer> offers, {required bool stale}) {
    if (offers.isEmpty) {
      return const MessageView(
        icon: Icons.medication_rounded,
        title: 'No hay medicamentos por ahora',
        message: 'Las centrales no tienen existencias para enviar por dron.',
      );
    }
    final shown = _filter.apply(offers);
    if (shown.isEmpty) {
      return MessageView(
        icon: Icons.search_off_rounded,
        title: 'Nada coincide',
        message: 'Prueba con otro nombre o quita los filtros.',
        action: OutlinedButton(
          onPressed: _clear,
          child: const Text('Quitar filtros'),
        ),
      );
    }
    return MedicationList(
      offers: shown,
      onOpen: _open,
      stale: stale,
      readAt: _readAt,
      onRetry: _reload,
    );
  }
}
