import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/field_limits.dart';
import '../../../core/widgets/app_snack.dart';
import '../../auth/presentation/widgets/auth_morph_button.dart';
import '../../home/presentation/widgets/section_form_page.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../../orders/data/order_models.dart';
import '../../orders/data/order_providers.dart';
import '../data/delivery_models.dart';
import '../data/delivery_providers.dart';
import 'widgets/receive/receive_order_card.dart';
import 'widgets/receive/transfer_checklist.dart';

/// El código de entrega y recibir el pedido (`/delivery/:orderId`), CU-19 y
/// CU-29.
///
/// El código se ve desde que se confirma la carga (`GET`, siempre el mismo).
/// Mientras el dron vuela se vuelve a pedir cada 10 s para saber cuándo
/// aterriza: ahí llega `expiresAt` y arranca la cuenta de 5 minutos. Quien
/// recibe lo escribe en el teclado del dron (simulado). Si la cuenta llega a
/// cero o se agotan los intentos, el dron vuelve con el paquete y aquí ya no
/// hay nada que hacer.
class ReceiveOrderScreen extends ConsumerStatefulWidget {
  const ReceiveOrderScreen({super.key, required this.orderId});

  final String orderId;

  static const expiredMessage =
      'El tiempo venció. El dron regresa con el paquete.';

  /// Texto de Nest al quinto código equivocado (`DELIVERY_CODE_LOCKED`).
  static const lockedMessage =
      'Se agotaron los intentos. El dron regresa con el paquete.';

  @override
  ConsumerState<ReceiveOrderScreen> createState() => _ReceiveOrderScreenState();
}

class _ReceiveOrderScreenState extends ConsumerState<ReceiveOrderScreen>
    with SingleTickerProviderStateMixin {
  final _input = TextEditingController();
  late final _collapse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  Timer? _timer;
  DeliveryCode? _code;
  Duration? _remaining;
  String? _error;
  bool _closed = false;
  bool _validating = false;
  bool _delivered = false;
  int _shakeCount = 0;
  bool? _remission;
  bool? _seal;

  bool get _canType => (_code?.landed ?? false) && !_closed && !_delivered;

  /// Un traslado: recibe la central de destino y revisa remisión y sello.
  bool get _isTransfer =>
      ref.watch(orderDetailProvider(widget.orderId)).value?.destinationKind ==
      DestinationKind.hub;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadCode);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _collapse.dispose();
    _input.dispose();
    super.dispose();
  }

  /// Lee el código. En vuelo vuelve a mirar cada 10 s; en tierra cuenta
  /// cada segundo hasta `expiresAt`.
  Future<void> _loadCode() async {
    try {
      final code = await ref
          .read(receiveOrderProvider.notifier)
          .code(widget.orderId);
      if (!mounted) return;
      setState(() {
        _code = code;
        _error = null;
      });
      _timer?.cancel();
      if (code.landed) {
        _tick();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      } else {
        _timer = Timer(const Duration(seconds: 10), _loadCode);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _tick() {
    final left = _code!.remaining(DateTime.now());
    setState(() => _remaining = left);
    if (left == Duration.zero && !_delivered) {
      _close(ReceiveOrderScreen.expiredMessage);
    }
  }

  /// Venció la espera o se agotaron los intentos: no se puede recibir.
  void _close(String message) {
    _timer?.cancel();
    setState(() {
      _closed = true;
      _error = message;
    });
  }

  Future<void> _submit() async {
    final code = _input.text.trim();
    if (code.length != FieldLimits.otpDigits) {
      setState(() {
        _error = 'Escribe los ${FieldLimits.otpDigits} dígitos del código.';
        _shakeCount++;
      });
      return;
    }
    setState(() {
      _validating = true;
      _error = null;
    });
    try {
      final transfer = _isTransfer;
      final order = await ref
          .read(receiveOrderProvider.notifier)
          .validate(
            widget.orderId,
            code,
            remissionMatches: transfer ? _remission : null,
            sealIntact: transfer ? _seal : null,
          );
      _timer?.cancel();
      // Se pudo salir de la pantalla mientras Nest respondía.
      if (!mounted) return;
      // Remisión, sello o frío no cuadran: no es un error, el dron vuelve.
      if (order.status == OrderStatus.returning) {
        final reason =
            order.receiptRejectedReason ??
            'El traslado no se recibió. El dron regresa con el paquete.';
        _close(reason);
        showAppSnack(context, reason, tone: SnackTone.warning);
        return;
      }
      setState(() => _delivered = true);
      await _collapse.forward();
      if (!mounted) return;
      showAppSnack(context, 'Pedido entregado.');
      SectionHeader.backOrHome(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      _input.clear();
      setState(() => _shakeCount++);
      if (e.message == ReceiveOrderScreen.lockedMessage) {
        _close(e.message);
      } else {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transfer = _isTransfer;
    final ready = _canType && !_validating;
    final checked = !transfer || TransferChecklist.answered(_remission, _seal);
    return SectionFormPage(
      header: SectionHeader(
        title: 'Recibir pedido',
        subtitle: 'Código de un solo uso',
        onBack: () => SectionHeader.backOrHome(context),
      ),
      card: ReceiveOrderCard(
        view: ReceiveOrderView(
          // Cerrada la entrega, el código ya no sirve: no se muestra.
          code: _closed ? null : _code,
          remaining: _remaining,
          error: _error,
          canType: _canType,
          shakeCount: _shakeCount,
          enabled: ready,
          isTransfer: transfer,
          remissionMatches: _remission,
          sealIntact: _seal,
        ),
        input: _input,
        collapse: _collapse,
        onSubmitted: checked ? _submit : () {},
        onRemission: (value) => setState(() => _remission = value),
        onSeal: (value) => setState(() => _seal = value),
      ),
      button: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: AuthMorphButton(
          label: 'Confirmar entrega',
          loadingLabel: 'Validando el código',
          isLoading: _validating,
          onPressed: ready && checked ? _submit : null,
        ),
      ),
    );
  }
}
