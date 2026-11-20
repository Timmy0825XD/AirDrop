import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api_exception.dart';
import '../../../../core/widgets/list_padding.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/sliding_segmented.dart';
import '../../data/geofence_models.dart';
import '../../data/geofence_providers.dart';
import 'geofence_delete_confirm.dart';
import 'geofence_detail_sheet.dart';
import 'geofence_tile.dart';

enum _Filter { all, operational, legal }

/// El catálogo con su filtro: todas, operativas o legales.
class GeofenceList extends ConsumerStatefulWidget {
  const GeofenceList({super.key, required this.isAdmin});

  final bool isAdmin;

  @override
  ConsumerState<GeofenceList> createState() => _GeofenceListState();
}

class _GeofenceListState extends ConsumerState<GeofenceList> {
  _Filter _filter = _Filter.all;

  bool _keep(Geofence g) => switch (_filter) {
    _Filter.all => true,
    _Filter.operational => g.isOperational,
    _Filter.legal => g.isLegal,
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(geofencesProvider);
    if (state case AsyncError(:final error)) {
      return MessageView.error(message: ApiException.messageOf(error));
    }
    final rows = state.value?.where(_keep).toList();
    if (rows == null) return const SkeletonList();
    return ListView.separated(
      padding: listPadding(context),
      itemCount: rows.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => i == 0
          ? SlidingSegmented<_Filter>(
              options: const [
                SegmentOption(_Filter.all, 'Todas'),
                SegmentOption(_Filter.operational, 'Operativas'),
                SegmentOption(_Filter.legal, 'Legales'),
              ],
              selected: _filter,
              onChanged: (value) => setState(() => _filter = value),
            )
          : RiseIn(
              key: ValueKey(rows[i - 1].id),
              delay: RiseIn.stagger(i - 1),
              child: _tile(rows[i - 1]),
            ),
    );
  }

  Widget _tile(Geofence geofence) {
    final manages = geofence.isOperational && !widget.isAdmin;
    return GeofenceTile(
      geofence: geofence,
      onTap: manages
          ? () => context.push('/geofences/${geofence.id}')
          : () => showGeofenceDetailSheet(
              context,
              geofence,
              isAdmin: widget.isAdmin,
            ),
      onDelete: manages ? () => deleteGeofence(context, ref, geofence) : null,
    );
  }
}
