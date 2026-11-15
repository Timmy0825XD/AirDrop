import 'package:flutter/material.dart';

import '../../../../../core/widgets/auth_field.dart';
import '../../../../../core/widgets/error_banner.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../auth/presentation/widgets/location_gps_row.dart';
import '../../../data/order_models.dart';
import 'delivery_point_tile.dart';
import 'delivery_points_map.dart';
import 'ground_alternative_card.dart';
import 'requester_order_fields.dart';
import 'requester_order_values.dart';

/// El paso "Dónde" (RU-02, RF-45): el dron baja en un punto de entrega, no
/// en una casa. "Usar mi ubicación" propone el más cercano; se puede elegir
/// otro en la lista o en el mapa. En la ciudad, o sin un punto al alcance,
/// dice por qué y dónde recoger el medicamento, y no deja pedir.
class DeliveryPointStep extends StatelessWidget {
  const DeliveryPointStep({super.key, required this.form});

  final RequesterOrderForm form;

  @override
  Widget build(BuildContext context) {
    final coverage = form.coverage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LocationGpsButton(
          locating: form.locating,
          onPressed: form.onUseMyLocation,
        ),
        const SizedBox(height: 16),
        if (form.coverageError case final error?) ...[
          ErrorBanner(message: error),
          TextButton(
            onPressed: form.onLoadCoverage,
            child: const Text('Reintentar'),
          ),
        ] else if (coverage == null)
          const _LoadingPoints()
        else if (!coverage.canOrder)
          GroundAlternativeCard(coverage: coverage)
        else
          _PointChoices(form: form, coverage: coverage),
      ],
    );
  }
}

/// Mientras llegan los puntos.
class _LoadingPoints extends StatelessWidget {
  const _LoadingPoints();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Buscando puntos de entrega',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Skeleton(height: 168, radius: 14),
          SizedBox(height: 12),
          Skeleton(height: 64, radius: 14),
          SizedBox(height: 10),
          Skeleton(height: 64, radius: 14),
        ],
      ),
    );
  }
}

/// El mapa con los puntos y la lista para elegir uno.
class _PointChoices extends StatelessWidget {
  const _PointChoices({required this.form, required this.coverage});

  final RequesterOrderForm form;
  final CoverageResult coverage;

  void _pick(DeliveryPoint point) {
    form.values.point = point;
    form.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chosen = form.values.point;
    final points = coverage.choices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Punto de entrega', style: authLabelStyle(theme)),
        const SizedBox(height: 8),
        DeliveryPointsMap(
          points: points,
          chosen: chosen,
          you: form.values.location,
          onPick: _pick,
        ),
        for (final point in points) ...[
          const SizedBox(height: 10),
          DeliveryPointTile(
            point: point,
            selected: point.id == chosen?.id,
            nearest: point.id == coverage.nearestPointId,
            onTap: () => _pick(point),
          ),
        ],
        AuthFieldError(message: form.errors[RequesterInput.location]),
        const SizedBox(height: 12),
        const PickupNote(),
      ],
    );
  }
}
