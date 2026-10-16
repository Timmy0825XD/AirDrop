import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'auth_brand.dart';
import 'auth_curved_header.dart';

/// Andamiaje de las pantallas de paso (verificar código, recuperar y nueva
/// contraseña): encabezado curvo con volver y pastilla, un ícono montado
/// sobre la curva, el contenido y, abajo, la acción principal.
///
/// Al entrar, el encabezado cambia desde la forma de la pantalla anterior
/// ([fromTall]: el login; si no, el registro) y el ícono aparece con un
/// rebote.
class AuthStepScaffold extends StatefulWidget {
  const AuthStepScaffold({
    super.key,
    this.pill,
    required this.onBack,
    required this.icon,
    required this.body,
    required this.action,
    this.fromTall = false,
    this.turnIcon = false,
    this.overlay,
  });

  final String? pill;
  final VoidCallback onBack;
  final IconData icon;
  final Widget body;
  final Widget action;
  final bool fromTall;

  /// El ícono entra girado y se endereza con el rebote (la llave).
  final bool turnIcon;

  /// Capa encima de todo (por ejemplo, el círculo de salida al inicio).
  final Widget? overlay;

  @override
  State<AuthStepScaffold> createState() => _AuthStepScaffoldState();
}

class _AuthStepScaffoldState extends State<AuthStepScaffold>
    with SingleTickerProviderStateMixin {
  late final _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  late final _header = CurvedAnimation(
    parent: _entry,
    curve: const Interval(0, 0.7, curve: Curves.fastOutSlowIn),
  );
  late final _pop = CurvedAnimation(
    parent: _entry,
    curve: const Interval(0.38, 1, curve: Curves.easeOutBack),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    MediaQuery.disableAnimationsOf(context)
        ? _entry.value = 1
        : _entry.forward();
  }

  @override
  void dispose() {
    _header.dispose();
    _pop.dispose();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: _StepHeader(entry: _header, fromTall: widget.fromTall),
            ),
            _StepContent(widget: widget, pop: _pop),
            if (widget.overlay != null) Positioned.fill(child: widget.overlay!),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.entry, required this.fromTall});

  final Animation<double> entry;
  final bool fromTall;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top;
    final from = fromTall
        ? AuthHeaderMetrics.tall(inset)
        : AuthHeaderMetrics.compact(inset);
    final fromCurve = fromTall
        ? AuthHeaderMetrics.tallCurve
        : AuthHeaderMetrics.compactCurve;
    return AnimatedBuilder(
      animation: entry,
      builder: (context, _) => AuthCurvedHeader(
        height: lerpDouble(from, AuthHeaderMetrics.step(inset), entry.value)!,
        curve: lerpDouble(fromCurve, AuthHeaderMetrics.stepCurve, entry.value)!,
      ),
    );
  }
}

/// Fila de volver y pastilla, el ícono, el contenido y la acción al fondo.
/// Con pantallas bajas o el teclado abierto, todo hace scroll.
class _StepContent extends StatelessWidget {
  const _StepContent({required this.widget, required this.pop});

  final AuthStepScaffold widget;
  final Animation<double> pop;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final padding = EdgeInsets.fromLTRB(
      24,
      AuthHeaderMetrics.brandTop(insets.top) - 2,
      24,
      28 + insets.bottom,
    );
    // Alto mínimo = la pantalla: la acción queda abajo si sobra espacio y,
    // si no alcanza, todo hace scroll.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - padding.vertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepTop(widget: widget, pop: pop),
              widget.action,
            ],
          ),
        ),
      ),
    );
  }
}

/// Volver y pastilla, el ícono y el contenido de la pantalla.
class _StepTop extends StatelessWidget {
  const _StepTop({required this.widget, required this.pop});

  final AuthStepScaffold widget;
  final Animation<double> pop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AuthBackButton(onPressed: widget.onBack),
            if (widget.pill case final pill?) AuthPill(text: pill),
          ],
        ),
        const SizedBox(height: 58),
        ScaleTransition(
          scale: pop,
          child: _StepIcon(
            icon: widget.icon,
            turns: widget.turnIcon ? _turn.animate(pop) : null,
          ),
        ),
        const SizedBox(height: 24),
        widget.body,
        const SizedBox(height: 24),
      ],
    );
  }
}

/// -40° a 0°, en vueltas: el giro de la llave al entrar.
final _turn = Tween<double>(begin: -40 / 360, end: 0);

/// Cuadro blanco con el ícono del paso; queda montado sobre la curva.
class _StepIcon extends StatelessWidget {
  const _StepIcon({required this.icon, this.turns});

  final IconData icon;
  final Animation<double>? turns;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final glyph = Icon(icon, size: 34, color: colors.primary);
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 44,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: turns == null
          ? glyph
          : RotationTransition(turns: turns!, child: glyph),
    );
  }
}
