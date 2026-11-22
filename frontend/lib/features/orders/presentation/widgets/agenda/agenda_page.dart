import 'package:flutter/material.dart';

import '../../../../../core/widgets/list_padding.dart';
import '../../../../../core/widgets/sim_clock_badge.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../home/presentation/widgets/home_link.dart';
import 'agenda_day_bar.dart';

class AgendaPage extends StatelessWidget {
  const AgendaPage({
    super.key,
    required this.date,
    required this.content,
    required this.onDateChanged,
    required this.onPick,
    required this.onRefresh,
    required this.onProgrammed,
  });
  final String date;
  final Widget content;
  final ValueChanged<String> onDateChanged;
  final VoidCallback onPick, onProgrammed;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: listPadding(context),
          children: [
            const _AgendaTitle(),
            const SizedBox(height: 24),
            AgendaDayBar(date: date, onChanged: onDateChanged, onPick: onPick),
            const SizedBox(height: 24),
            content,
            const SizedBox(height: 24),
            HomeLink(
              title: 'Ver todos los programados',
              subtitle: 'Consulta las entregas pendientes',
              icon: AppIcons.document,
              onTap: onProgrammed,
            ),
          ],
        ),
      ),
    ),
  );
}

class _AgendaTitle extends StatelessWidget {
  const _AgendaTitle();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Agenda',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Las entregas de tu central, por horario.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SimClockBadge(top: 10),
    ],
  );
}
