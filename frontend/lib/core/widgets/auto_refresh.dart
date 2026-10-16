import 'dart:async';

import 'package:flutter/widgets.dart';

/// Llama [onTick] cada [every] mientras la pantalla está abierta.
///
/// Las listas del despachador y el historial no tienen socket: sin esto,
/// un pedido nuevo o un cambio de estado solo aparecía al recargar. El
/// reloj se apaga al salir de la pantalla.
class AutoRefresh extends StatefulWidget {
  const AutoRefresh({
    super.key,
    required this.onTick,
    required this.child,
    this.every = defaultInterval,
  });

  static const defaultInterval = Duration(seconds: 10);

  final VoidCallback onTick;
  final Duration every;
  final Widget child;

  @override
  State<AutoRefresh> createState() => _AutoRefreshState();
}

class _AutoRefreshState extends State<AutoRefresh> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.every, (_) => widget.onTick());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
