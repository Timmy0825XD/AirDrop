import 'package:flutter/material.dart';

import '../../../../../core/widgets/status_pill.dart';
import '../../../../hubs/presentation/widgets/hub_outage.dart';
import '../../live_mission.dart';
import '../home_page.dart';
import '../home_section_heading.dart';
import 'dispatcher_activity.dart';
import 'dispatcher_home_header.dart';
import 'dispatcher_home_links.dart';
import 'dispatcher_home_values.dart';
import 'dispatcher_hub_state.dart';
import 'dispatcher_tasks.dart';
import 'dispatcher_urgent_action.dart';

class DispatcherHomePage extends StatelessWidget {
  const DispatcherHomePage({
    super.key,
    required this.data,
    required this.fullName,
    required this.onOpen,
    required this.onRetry,
    this.unread,
  });
  final DispatcherHomeValues data;
  final String fullName;
  final int? unread;
  final ValueChanged<String> onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final outage = hubOutageNote(data.hub.value);
    return HomePage(
      children: [
        DispatcherHomeHeader(
          fullName: fullName,
          hubName: data.hubName,
          status: data.hubStatus,
          tone: data.active && outage == null
              ? PillTone.positive
              : PillTone.attention,
          onNotices: () => onOpen('/notifications'),
          unread: unread,
        ),
        const SizedBox(height: 24),
        if (!data.active) DispatcherHubState(data: data, onRetry: onRetry),
        if (data.active) ...[
          if (outage != null) ...[
            HubOutageBanner(note: outage),
            const SizedBox(height: 16),
          ],
          DispatcherOperation(data: data, onOpen: onOpen, onRetry: onRetry),
        ],
        const SizedBox(height: 24),
        DispatcherHomeLinks(
          active: data.active,
          hasHub: data.hub.value != null,
          onOpen: onOpen,
        ),
      ],
    );
  }
}

class DispatcherOperation extends StatelessWidget {
  const DispatcherOperation({
    super.key,
    required this.data,
    required this.onOpen,
    required this.onRetry,
  });
  final DispatcherHomeValues data;
  final ValueChanged<String> onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final flying = data.firstFlight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DispatcherUrgentAction(
          count: data.counts.queue,
          onTap: () => onOpen('/orders/queue'),
        ),
        const SizedBox(height: 28),
        DispatcherTasks(data: data, onOpen: onOpen, onRetry: onRetry),
        const SizedBox(height: 24),
        DispatcherActivity(counts: data.counts, onOpen: onOpen),
        if (flying != null) ...[
          const SizedBox(height: 24),
          HomeSectionHeading(
            title: 'Vuelos de tu central',
            onViewAll: () => onOpen('/orders/in-flight'),
          ),
          LiveMission(order: flying),
        ],
      ],
    );
  }
}
