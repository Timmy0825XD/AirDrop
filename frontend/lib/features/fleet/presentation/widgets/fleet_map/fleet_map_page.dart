import 'package:flutter/material.dart';

import '../../../../../core/widgets/map_sheet.dart';
import '../../../../../core/widgets/message_view.dart';
import '../../../data/fleet_flight.dart';
import '../../../data/fleet_map_models.dart';
import 'fleet_live_map.dart';
import 'fleet_map_header.dart';
import 'fleet_map_sheet.dart';
import 'fleet_map_values.dart';

class FleetMapPage extends StatefulWidget {
  const FleetMapPage({
    super.key,
    required this.values,
    required this.incidents,
    required this.onFlight,
    required this.onDrone,
    required this.onRetry,
    this.problem,
  });
  final FleetMapValues values;
  final List<FleetIncident> incidents;
  final ValueChanged<FleetFlight> onFlight, onDrone;
  final VoidCallback onRetry;
  final String? problem;

  @override
  State<FleetMapPage> createState() => _FleetMapPageState();
}

class _FleetMapPageState extends State<FleetMapPage> {
  final _sheet = DraggableScrollableController();
  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.values.map;
    return MapSheetScaffold(
      title: 'Mapa en vivo',
      onBack: () {},
      header: FleetMapHeader(
        count: map?.flights.length,
        hasProblem: widget.problem != null,
      ),
      sheetController: _sheet,
      sheetFraction: MediaQuery.textScalerOf(context).scale(14) > 21
          ? .56
          : .44,
      minSheetFraction: .25,
      map: (height) => map == null
          ? const SizedBox.expand()
          : FleetLiveMap(
              map: map,
              incidents: widget.incidents,
              sheetHeight: height,
              onDrone: widget.onDrone,
            ),
      sheet: map == null
          ? [
              if (widget.problem case final problem?)
                MessageView.error(
                  message: problem,
                  action: TextButton(
                    onPressed: widget.onRetry,
                    child: const Text('Reintentar'),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ]
          : fleetMapSheet(
              context: context,
              map: map,
              incidents: widget.incidents,
              onFlight: widget.onFlight,
              values: widget.values,
              problem: widget.problem,
              onRetry: widget.onRetry,
            ),
    );
  }
}
