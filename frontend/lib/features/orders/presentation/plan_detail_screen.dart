import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/error_banner.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';

/// Detalle del plan con ocurrencias y botones Extender / Cancelar.
class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  String? _error;
  bool _busy = false;

  Future<void> _extend() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Extender plan'),
        content: const Text('Se agregan otras 8 semanas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Extender'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(extendPlanProvider.notifier).extend(widget.planId);
      if (mounted) showAppSnack(context, 'Plan extendido.');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cancelar plan'),
        content: const Text(
          'Las entregas que siguen en recibido quedan canceladas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Cancelar plan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(cancelPlanProvider.notifier).cancel(widget.planId);
      if (mounted) showAppSnack(context, 'Plan cancelado.');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(planDetailProvider(widget.planId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del plan')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (value) {
          final plan = value.plan;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null) ...[
                ErrorBanner(message: _error!),
                const SizedBox(height: 12),
              ],
              Text(plan.medicationName,
                  style: Theme.of(context).textTheme.titleLarge),
              Text(
                '${plan.frequency.label} · ${plan.startDate} - ${plan.windowEndsOn} · ${plan.status.label}',
              ),
              const SizedBox(height: 12),
              for (final o in value.occurrences)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(o.scheduledFor),
                  subtitle: Text(o.status.label),
                  trailing: Text(
                    o.droneId == null ? 'Sin dron asignado' : o.droneId!,
                  ),
                ),
              const SizedBox(height: 12),
              if (plan.renewalDue)
                FilledButton(
                  onPressed: _busy ? null : _extend,
                  child: const Text('Extender'),
                ),
              if (plan.status == PlanStatus.active) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : _cancel,
                  child: const Text('Cancelar'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
