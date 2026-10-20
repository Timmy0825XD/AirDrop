import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/field_limits.dart';
import '../../../core/widgets/app_snack.dart';
import '../../auth/presentation/widgets/auth_morph_button.dart';
import '../../home/presentation/widgets/section_form_page.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/delivery_models.dart';
import '../data/delivery_providers.dart';
import 'widgets/receive/receive_order_card.dart';

/// Recibir un pedido en destino (`/delivery/:orderId`), CU-19 y CU-29.
///
/// Al abrir pide el código a Nest (solo sale con el dron en tierra) y cuenta
/// los 5 minutos de espera. Quien recibe lo escribe en el teclado del dron
/// (simulado): válido, el pedido queda entregado. Si la cuenta llega a cero,
/// el dron vuelve con el paquete y aquí ya no hay nada que hacer.
class ReceiveOrderScreen extends ConsumerStatefulWidget {
  const ReceiveOrderScreen({super.key, required this.orderId});

  final String orderId;

  static const expiredMessage =
      'El tiempo para recibir el pedido venció. El dron vuelve a la central '
      'con el paquete.';

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
  Timer? _ticker;
  DeliveryCode? _code;
  Duration _remaining = Duration.zero;
  String? _error;
  bool _validating = false;
  bool _delivered = false;
  int _shakeCount = 0;

  bool get _expired => _code != null && _remaining == Duration.zero;

  @override
  void initState() {
    super.initState();
    Future.microtask(_requestCode);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _collapse.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    try {
      final code = await ref
          .read(receiveOrderProvider.notifier)
          .generate(widget.orderId);
      if (!mounted) return;
      setState(() => _code = code);
      _tick();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _tick() {
    final left = _code!.remaining(DateTime.now());
    setState(() {
      _remaining = left;
      if (left == Duration.zero && !_delivered) {
        _ticker?.cancel();
        _error = ReceiveOrderScreen.expiredMessage;
      }
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
      await ref
          .read(receiveOrderProvider.notifier)
          .validate(widget.orderId, code);
      _ticker?.cancel();
      setState(() => _delivered = true);
      await _collapse.forward();
      if (!mounted) return;
      showAppSnack(context, 'Pedido entregado.');
      SectionHeader.backOrHome(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _shakeCount++;
        _input.clear();
      });
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _code != null && !_expired && !_delivered;
    return SectionFormPage(
      header: SectionHeader(
        title: 'Recibir pedido',
        subtitle: 'Código de un solo uso',
        onBack: () => SectionHeader.backOrHome(context),
      ),
      card: ReceiveOrderCard(
        view: ReceiveOrderView(
          code: _code,
          remaining: _remaining,
          error: _error,
          expired: _expired,
          hasError: _error != null,
          shakeCount: _shakeCount,
          enabled: ready && !_validating,
        ),
        input: _input,
        collapse: _collapse,
        onSubmitted: _submit,
      ),
      button: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: AuthMorphButton(
          label: 'Recibir pedido',
          loadingLabel: 'Validando el código',
          isLoading: _validating,
          onPressed: ready && !_validating ? _submit : null,
        ),
      ),
    );
  }
}
