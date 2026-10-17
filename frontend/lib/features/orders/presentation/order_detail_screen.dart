import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/field_limits.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'order_format.dart';
import 'widgets/order_detail/authorize_section.dart';
import 'widgets/order_detail/confirm_load_section.dart';
import 'widgets/order_detail/dispatcher_permissions.dart';
import 'widgets/order_detail/order_assignment_card.dart';
import 'widgets/order_detail/order_summary.dart';
import 'widgets/order_detail/prescription_viewer.dart';
import 'widgets/order_detail/reject_section.dart';
import 'widgets/watch_flight_button.dart';

/// Lo que se está haciendo sobre el pedido, para mostrar el dron girando
/// solo en ese botón.
enum _Action { authorize, reject, confirmLoad, prescription }

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
  _Action? _running;
  String? _error;
  String? _reasonError;
  int _shakeCount = 0;

  bool get _busy => _running != null;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  OrderDispatchNotifier get _dispatch =>
      ref.read(orderDispatchProvider.notifier);

  /// Corre una acción con los botones apagados y muestra el mensaje de Nest
  /// si falla.
  Future<void> _act(_Action action, Future<void> Function() run) async {
    setState(() {
      _running = action;
      _error = null;
    });
    try {
      await run();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  Future<void> _authorize(DispatcherPermissions can) =>
      _act(_Action.authorize, () async {
        await _dispatch.authorize(
          widget.orderId,
          prescriptionVerified: can.needsPrescriptionCheck ? true : null,
        );
        if (!mounted) return;
        showAppSnack(context, 'Pedido autorizado. Falta confirmar la carga.');
      });

  Future<void> _confirmLoad() => _act(_Action.confirmLoad, () async {
    await _dispatch.confirmLoad(widget.orderId);
    if (!mounted) return;
    showAppSnack(context, 'Carga confirmada. El vuelo arranca en segundos.');
  });

  Future<void> _reject() async {
    final reason = _reason.text.trim();
    final error = reason.isEmpty || reason.length > FieldLimits.reason
        ? 'El motivo del rechazo es obligatorio.'
        : null;
    setState(() {
      _reasonError = error;
      if (error != null) _shakeCount++;
    });
    if (error != null) return;
    await _act(_Action.reject, () async {
      await _dispatch.reject(widget.orderId, reason);
      if (!mounted) return;
      showAppSnack(context, 'Pedido rechazado.');
      // Rechazado, sale de la cola y la central ya no lo puede abrir.
      SectionHeader.backOrHome(context);
    });
  }

  Future<void> _viewPrescription() => _act(_Action.prescription, () async {
    final file = await ref
        .read(orderRepositoryProvider)
        .prescription(widget.orderId);
    if (mounted) await showPrescription(context, file);
  });

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(orderDetailProvider(widget.orderId));
    // El último pedido leído, también mientras recarga.
    final order = detail.value;
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: order?.medicationName ?? 'Pedido',
            subtitle: order == null
                ? 'Detalle del pedido'
                : '${order.missionType.label} · ${destinationLabel(order)}',
            onBack: () => SectionHeader.backOrHome(context),
          ),
          Expanded(
            // Sin socket en el detalle: se pide de nuevo cada 10 s, así el
            // estado no se queda en "Pendiente de carga" con el dron volando.
            child: AutoRefresh(
              onTick: () => ref.invalidate(orderDetailProvider(widget.orderId)),
              child: switch (detail) {
                AsyncValue(hasValue: true, hasError: false, :final value?) =>
                  _content(value),
                AsyncError(:final error) => MessageView(
                  icon: Icons.cloud_off_rounded,
                  message: ApiException.messageOf(error),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(Order order) {
    final user = ref.watch(authControllerProvider).value?.user;
    final isDispatcher = user?.role == UserRole.dispatcher;
    final blocks = <Widget>[
      if (_error != null) ErrorBanner(message: _error!),
      OrderSummary(order: order, showPrescriptionFlag: !isDispatcher),
      if (order.assignment != null)
        OrderAssignmentCard(
          assignment: order.assignment!,
          loadConfirmedAt: order.loadConfirmedAt,
        ),
      if (isDispatcher)
        ..._dispatcherActions(
          DispatcherPermissions(
            order: order,
            myHubId: user!.hubIds.firstOrNull,
          ),
        )
      // El solicitante solo abre sus pedidos, así que el vuelo es suyo.
      else if (order.hasFlight)
        WatchFlightButton(orderId: order.id),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      itemCount: blocks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) =>
          RiseIn(delay: RiseIn.stagger(i), child: blocks[i]),
    );
  }

  List<Widget> _dispatcherActions(DispatcherPermissions can) {
    return [
      if (can.canDecide) ...[
        AuthorizeSection(
          needsPrescriptionCheck: can.needsPrescriptionCheck,
          prescriptionVerified: _prescriptionVerified,
          onVerifiedChanged: (v) => setState(() => _prescriptionVerified = v),
          onViewPrescription: can.canViewPrescription
              ? _viewPrescription
              : null,
          notYet: can.notYet,
          busy: _busy,
          loading: _running == _Action.authorize,
          onAuthorize: () => _authorize(can),
        ),
        RejectSection(
          reason: _reason,
          errorText: _reasonError,
          shakeCount: _shakeCount,
          busy: _busy,
          onReject: _reject,
        ),
      ],
      if (can.canConfirmLoad)
        ConfirmLoadSection(
          busy: _busy,
          loading: _running == _Action.confirmLoad,
          onConfirm: _confirmLoad,
        ),
      if (can.canWatchFlight) WatchFlightButton(orderId: can.order.id),
    ];
  }
}
