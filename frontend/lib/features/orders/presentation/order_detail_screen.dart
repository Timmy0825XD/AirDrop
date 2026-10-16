import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/field_limits.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/error_banner.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/order_providers.dart';
import 'widgets/order_detail/authorize_section.dart';
import 'widgets/order_detail/confirm_load_section.dart';
import 'widgets/order_detail/dispatcher_permissions.dart';
import 'widgets/order_detail/order_assignment_card.dart';
import 'widgets/order_detail/order_summary.dart';
import 'widgets/order_detail/prescription_viewer.dart';
import 'widgets/order_detail/reject_section.dart';

/// Detalle del pedido (`GET /orders/:id`).
///
/// El solicitante solo lo ve. El despachador, según el estado y su central:
/// en `received` autoriza (revisando la fórmula si aplica) o rechaza; en
/// "Pendiente de carga" confirma la carga para que arranque el vuelo.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  final _reason = TextEditingController();
  bool _prescriptionVerified = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  OrderDispatchNotifier get _dispatch =>
      ref.read(orderDispatchProvider.notifier);

  /// Corre una acción con el botón bloqueado y muestra el mensaje de Nest
  /// si falla.
  Future<void> _act(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _authorize(DispatcherPermissions can) => _act(() async {
    await _dispatch.authorize(
      widget.orderId,
      prescriptionVerified: can.needsPrescriptionCheck ? true : null,
    );
    if (!mounted) return;
    showAppSnack(context, 'Pedido autorizado. Falta confirmar la carga.');
  });

  Future<void> _confirmLoad() => _act(() async {
    await _dispatch.confirmLoad(widget.orderId);
    if (!mounted) return;
    showAppSnack(context, 'Carga confirmada. El vuelo arranca en segundos.');
  });

  Future<void> _reject() async {
    final reason = _reason.text.trim();
    if (reason.isEmpty || reason.length > FieldLimits.reason) {
      setState(() => _error = 'El motivo del rechazo es obligatorio.');
      return;
    }
    await _act(() async {
      await _dispatch.reject(widget.orderId, reason);
      if (mounted) showAppSnack(context, 'Pedido rechazado.');
    });
  }

  Future<void> _viewPrescription() => _act(() async {
    final file = await ref
        .read(orderRepositoryProvider)
        .prescription(widget.orderId);
    if (mounted) await showPrescription(context, file);
  });

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(orderDetailProvider(widget.orderId));
    final user = ref.watch(authControllerProvider).asData?.value.user;
    final isDispatcher = user?.role == UserRole.dispatcher;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del pedido')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (order) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 12),
            ],
            OrderSummary(order: order, showPrescriptionFlag: !isDispatcher),
            if (order.assignment != null) ...[
              const SizedBox(height: 12),
              OrderAssignmentCard(
                assignment: order.assignment!,
                loadConfirmedAt: order.loadConfirmedAt,
              ),
            ],
            if (isDispatcher)
              ..._dispatcherActions(
                DispatcherPermissions(
                  order: order,
                  myHubId: user!.hubIds.firstOrNull,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _dispatcherActions(DispatcherPermissions can) {
    return [
      if (can.canDecide) ...[
        const SizedBox(height: 12),
        AuthorizeSection(
          needsPrescriptionCheck: can.needsPrescriptionCheck,
          prescriptionVerified: _prescriptionVerified,
          onVerifiedChanged: (v) => setState(() => _prescriptionVerified = v),
          onViewPrescription: can.canViewPrescription
              ? _viewPrescription
              : null,
          notYet: can.notYet,
          busy: _busy,
          onAuthorize: () => _authorize(can),
        ),
        const SizedBox(height: 12),
        RejectSection(reason: _reason, busy: _busy, onReject: _reject),
      ],
      if (can.canConfirmLoad) ...[
        const SizedBox(height: 12),
        ConfirmLoadSection(busy: _busy, onConfirm: _confirmLoad),
      ],
    ];
  }
}
