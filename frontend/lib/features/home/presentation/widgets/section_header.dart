import 'package:flutter/material.dart';

import '../../../auth/presentation/widgets/auth_brand.dart';
import '../../../auth/presentation/widgets/auth_curved_header.dart';

/// Encabezado curvo de las pantallas de trabajo: volver, título y una
/// línea de contexto. Es el mismo bloque de marca de auth, en compacto.
///
/// Con [bottom] (un filtro, por ejemplo) ese widget queda montado sobre la
/// curva, mitad adentro y mitad afuera, como en el diseño.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.bottom,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget? bottom;

  /// Cuánto del [bottom] cae debajo de la curva.
  static const double overlap = 26;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final height = top + 120;
    return SizedBox(
      height: height + (bottom == null ? 0 : overlap),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: height,
            child: AuthCurvedHeader(height: height, curve: 32),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: top + 14,
            child: _TitleRow(title: title, subtitle: subtitle, onBack: onBack),
          ),
          if (bottom != null)
            Positioned(left: 20, right: 20, bottom: 0, child: bottom!),
        ],
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onBrand = theme.colorScheme.onPrimary;
    return Row(
      children: [
        AuthBackButton(onPressed: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: onBrand,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onBrand.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
