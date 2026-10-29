import 'package:flutter/material.dart';

import '../../../../../core/widgets/error_banner.dart';
import '../../order_format.dart';

/// RF-17: la temperatura de la carga salió de 2 a 8 °C en algún momento
/// del vuelo. Un retorno con esta marca va a cuarentena.
class ColdChainBanner extends StatelessWidget {
  const ColdChainBanner({super.key, this.at});

  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    final when = at == null ? '' : ' (${formatBogota(at)})';
    return ErrorBanner(
      message: 'Alerta de frío: la carga salió del rango de 2 a 8 °C$when.',
    );
  }
}
