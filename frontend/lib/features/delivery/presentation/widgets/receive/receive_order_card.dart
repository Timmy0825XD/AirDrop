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
    required this.expired,
    required this.hasError,
    required this.shakeCount,
    required this.enabled,
  });

  /// `null` mientras Nest lo genera o si no lo pudo generar.
  final DeliveryCode? code;
  final Duration remaining;
  final String? error;
  final bool expired;
  final bool hasError;
  final int shakeCount;
  final bool enabled;
}

/// La tarjeta de recibir: el aviso, el código con su cuenta regresiva y el
/// teclado del dron (simulado) donde se escribe para cerrar la entrega.
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
    return FormSheetCard(
      children: [
        if (view.error case final error?) ...[
          ErrorBanner(message: error, success: false),
          const SizedBox(height: 14),
        ],
        if (code == null && view.error == null)
          const Center(child: CircularProgressIndicator())
        else if (code != null && !view.expired) ...[
          DeliveryCodeBadge(code: code.code, remaining: view.remaining),
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
            hasError: view.hasError,
            shakeCount: view.shakeCount,
            enabled: view.enabled,
            onSubmitted: onSubmitted,
          ),
        ],
      ],
    );
  }
}
