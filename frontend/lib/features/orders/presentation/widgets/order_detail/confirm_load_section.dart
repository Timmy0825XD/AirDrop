import 'package:flutter/material.dart';

import '../../../../../core/widgets/detail_section.dart';
import '../../../../auth/presentation/widgets/auth_morph_button.dart';

/// Confirmar la carga: el despachador de la central de origen avisa que el
/// insumo ya va en el dron. Recién ahí arranca la simulación del vuelo. El
/// botón abre la revisión (`showLoadCheckSheet`); el vuelo sale al deslizar.
class ConfirmLoadSection extends StatelessWidget {
  const ConfirmLoadSection({
    super.key,
    required this.busy,
    required this.loading,
    required this.onConfirm,
  });

  final bool busy;
  final bool loading;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      title: 'Confirmar carga',
      icon: Icons.inventory_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pon el insumo en el dron y revisa lo que va. Al deslizar para '
            'despegar, el vuelo arranca en segundos.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          AuthMorphButton(
            label: 'Revisar y cargar',
            loadingLabel: 'Confirmando la carga',
            isLoading: loading,
            onPressed: busy ? null : onConfirm,
          ),
        ],
      ),
    );
  }
}
