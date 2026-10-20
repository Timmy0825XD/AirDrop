import 'package:flutter/material.dart';

import '../../../../../core/widgets/error_banner.dart';
import '../../../../../core/widgets/form_sheet_card.dart';
import '../../../../auth/presentation/widgets/otp/otp_code_field.dart';
import '../../../data/delivery_models.dart';
import 'delivery_code_badge.dart';

/// Lo que la pantalla de recibir le pasa a la tarjeta.
class ReceiveOrderView {
  const ReceiveOrderView({
    required this.code,
    required this.remaining,
    required this.error,
    required this.canType,
    required this.shakeCount,
    required this.enabled,
  });

  /// `null` mientras llega de Nest o si Nest no lo dio.
  final DeliveryCode? code;

  /// `null` mientras el dron vuela.
  final Duration? remaining;
  final String? error;

  /// El dron está en tierra, no venció la espera y quedan intentos.
  final bool canType;
  final int shakeCount;
  final bool enabled;

  String get caption => switch (remaining) {
    null => 'El dron va en camino. Lo escribes cuando aterrice.',
    final left => 'Vence en ${DeliveryCodeBadge.clock(left)}',
  };
}

/// La tarjeta de recibir: el aviso, el código (visible desde que el dron
/// despega) y, con el dron en tierra, el teclado del dron (simulado) donde
/// se escribe para cerrar la entrega.
class ReceiveOrderCard extends StatelessWidget {
  const ReceiveOrderCard({
    super.key,
    required this.view,
    required this.input,
    required this.collapse,
    required this.onSubmitted,
  });

  final ReceiveOrderView view;
  final TextEditingController input;
  final Animation<double> collapse;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = view.code;
    final hurry = (view.remaining?.inSeconds ?? 60) < 60;
    return FormSheetCard(
      children: [
        if (view.error case final error?) ...[
          ErrorBanner(message: error, success: false),
          const SizedBox(height: 14),
        ],
        if (code == null && view.error == null)
          const Center(child: CircularProgressIndicator()),
        if (code != null)
          DeliveryCodeBadge(
            code: code.code,
            caption: view.caption,
            hurry: hurry,
          ),
        if (view.canType) ...[
          const SizedBox(height: 16),
          Text('TECLADO DEL DRON', style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            'Escribe el código en el dron para recibir el paquete.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          OtpCodeField(
            controller: input,
            collapse: collapse,
            hasError: view.error != null,
            shakeCount: view.shakeCount,
            enabled: view.enabled,
            onSubmitted: onSubmitted,
          ),
        ],
      ],
    );
  }
}
