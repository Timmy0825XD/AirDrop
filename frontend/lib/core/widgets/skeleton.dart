import 'package:flutter/material.dart';

/// Un bloque del esqueleto de carga: ocupa el lugar del contenido que
/// viene, con un brillo que late despacio. Con "reducir movimiento" queda
/// quieto. El color sale del tema.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 14, this.radius = 7});

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    still ? _pulse.stop() : _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final base = colors.onSurface.withValues(alpha: 0.08);
    final peak = colors.onSurface.withValues(alpha: 0.16);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(base, peak, _pulse.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// El esqueleto de una lista: [rows] tarjetas con el ícono y dos líneas,
/// como las filas que van a llegar. Reemplaza al indicador girando en las
/// pantallas de lista (RNF-18).
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 4});

  final int rows;

  @override
  Widget build(BuildContext context) => _SkeletonFrame(
    children: [for (var i = 0; i < rows; i++) const _SkeletonRow()],
  );
}

/// El esqueleto de un detalle o un formulario: el título, un bloque grande
/// y unas líneas debajo.
class SkeletonDetail extends StatelessWidget {
  const SkeletonDetail({super.key});

  @override
  Widget build(BuildContext context) => const _SkeletonFrame(
    children: [
      Skeleton(width: 180, height: 22),
      Skeleton(height: 120, radius: 20),
      Skeleton(width: 240),
      Skeleton(),
      Skeleton(width: 160),
    ],
  );
}

/// Acomoda los bloques arriba, con el margen de las listas, sin desbordar
/// si la pantalla es baja. El lector de pantalla dice "Cargando".
class _SkeletonFrame extends StatelessWidget {
  const _SkeletonFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando',
      liveRegion: true,
      child: ExcludeSemantics(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final child in children)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: child,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una fila en reposo: la tarjeta con el cuadro del ícono y dos líneas.
class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: const Row(
        children: [
          Skeleton(width: 44, height: 44, radius: 12),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(widthFactor: 0.7, child: Skeleton()),
                SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.45,
                  child: Skeleton(height: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
