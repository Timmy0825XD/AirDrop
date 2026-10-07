import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/field_limits.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/error_banner.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../inventory/data/inventory_models.dart' show SaleType;
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'order_format.dart';
import 'widgets/prescription_checklist.dart';

/// Detalle del pedido (`GET /orders/:id`). El despachador rechaza en
/// `received` y ve la fórmula solo en urgencia civil bajo fórmula.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  final _reason = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool _canSeePrescription(Order order) {
    return order.missionType == MissionType.emergency &&
        order.destinationKind == DestinationKind.person &&
        order.saleType == SaleType.prescription &&
        order.status == OrderStatus.received;
  }

  Future<void> _reject() async {
    final reason = _reason.text.trim();
    if (reason.isEmpty || reason.length > FieldLimits.reason) {
      setState(() => _error = 'El motivo del rechazo es obligatorio.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(rejectOrderProvider.notifier).reject(
            widget.orderId,
            reason,
          );
      if (mounted) showAppSnack(context, 'Pedido rechazado.');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _viewPrescription() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await ref
          .read(orderRepositoryProvider)
          .prescription(widget.orderId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => Dialog(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Fórmula'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(c).pop(),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Image.memory(file.bytes),
                const SizedBox(height: 12),
                const PrescriptionChecklist(),
              ],
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(orderDetailProvider(widget.orderId));
    final auth = ref.watch(authControllerProvider).asData?.value;
    final isDispatcher = auth?.user?.role == UserRole.dispatcher;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del pedido')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (order) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null) ...[
                ErrorBanner(message: _error!),
                const SizedBox(height: 12),
              ],
              Text(order.medicationName,
                  style: Theme.of(context).textTheme.titleLarge),
              Text(
                '${order.saleType.label} · ${order.quantity} und. · '
                '${order.status.label} · Prioridad ${order.priority.label}',
              ),
              if (order.description != null)
                Text('Descripción: ${order.description}'),
              Text('Dirección: ${order.address}'),
              if (order.statusReason != null)
                Text('Motivo: ${order.statusReason}'),
              Text('Dron: ${order.droneId ?? 'Sin dron asignado'}'),
              if (order.scheduledFor != null)
                Text('Programada: ${order.scheduledFor}'),
              Text('Creado: ${formatBogota(order.createdAt)}'),
              if (order.requiresColdChain)
                const Text('Requiere frío'),
              if (order.hasPrescription && !isDispatcher)
                const Text('Lleva fórmula'),
              const SizedBox(height: 16),
              if (isDispatcher && order.status == OrderStatus.received) ...[
                TextField(
                  controller: _reason,
                  maxLength: FieldLimits.reason,
                  decoration: const InputDecoration(
                    labelText: 'MOTIVO DE RECHAZO',
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _busy ? null : _reject,
                  child: const Text('Rechazar pedido'),
                ),
              ],
              if (isDispatcher && _canSeePrescription(order)) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : _viewPrescription,
                  child: const Text('Ver fórmula'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
