import 'package:flutter/material.dart';

import '../../../../../core/widgets/detail_section.dart';
import '../../../../../core/widgets/error_banner.dart';
import '../../../../../core/widgets/yes_no_question.dart';
import '../../../../auth/presentation/widgets/auth_morph_button.dart';

/// HU-34: el paquete volvió a la central de origen y alguien tiene que
/// revisarlo una vez. Con empaque íntegro y sin alerta de frío vuelve al
/// inventario; si no, va a cuarentena (productos.md).
class ReturnCheckSection extends StatelessWidget {
  const ReturnCheckSection({
    super.key,
    required this.coldChainAlert,
    required this.packagingIntact,
    required this.onChanged,
    required this.busy,
    required this.loading,
    required this.onSubmit,
  });

  final bool coldChainAlert;

  /// `null` mientras no se responde.
  final bool? packagingIntact;
  final ValueChanged<bool> onChanged;
  final bool busy;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      title: 'Revisar el retorno',
      icon: Icons.inventory_2_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (coldChainAlert) ...[
            const ErrorBanner(
              message: 'Hubo alerta de frío: este lote irá a cuarentena.',
            ),
            const SizedBox(height: 12),
          ],
          YesNoQuestion(
            question: '¿El empaque llegó íntegro?',
            value: packagingIntact,
            onChanged: onChanged,
            enabled: !busy,
          ),
          const SizedBox(height: 14),
          AuthMorphButton(
            label: 'Registrar revisión',
            loadingLabel: 'Registrando la revisión',
            isLoading: loading,
            onPressed: packagingIntact != null && !busy ? onSubmit : null,
          ),
        ],
      ),
    );
  }
}
