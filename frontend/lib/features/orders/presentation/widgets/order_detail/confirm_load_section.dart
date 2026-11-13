import 'package:flutter/material.dart';

import '../../../../../core/widgets/detail_section.dart';
import '../../../../../core/widgets/auth_morph_button.dart';

/// Confirmar la carga: el despachador de la central de origen avisa que el
/// insumo ya va en el dron. Recién ahí arranca la simulación del vuelo. El
/// botón abre la revisión (`showLoadCheckSheet`); el vuelo sale al deslizar.
class ConfirmLoadSection extends StatelessWidget {
  const ConfirmLoadSection({
    super.key,
    required this.busy,
    required this.loading,
    required this.onConfirm,
    this.blockedNote,
  });

  final bool busy;
  final bool loading;
  final VoidCallback onConfirm;

  /// Por qué no se puede cargar ahora (la central sin energía); `null` si
  /// se puede. Apaga el botón en vez de dejar que Nest responda 409.
  final String? blockedNote;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      title: 'Confirmar carga',
      icon: Icons.inventory_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            blockedNote ??
                'Pon el insumo en el dron y revisa lo que va. Al deslizar '
                    'para despegar, el vuelo arranca en segundos.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          AuthMorphButton(
            label: 'Revisar y cargar',
            loadingLabel: 'Confirmando la carga',
            isLoading: loading,
            onPressed: busy || blockedNote != null ? null : onConfirm,
          ),
        ],
      ),
    );
  }
}
