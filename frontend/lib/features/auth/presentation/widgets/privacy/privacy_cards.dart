import 'package:flutter/material.dart';

import '../../../../../core/date_format.dart';
import '../../../../../core/widgets/detail_section.dart';
import '../../../data/privacy_models.dart';

/// "Aceptaste la versión 1.0 · sáb. 14 nov. · 9:50 a. m."
String consentSummary(ConsentState consent) {
  final version = consent.acceptedVersion;
  if (version == null) return 'Todavía no has aceptado la política vigente.';
  final at = consent.acceptedAt;
  return at == null
      ? 'Aceptaste la versión $version.'
      : 'Aceptaste la versión $version · ${formatDateTime(at)}';
}

/// Qué política aceptó la cuenta, con el enlace para leerla.
class ConsentCard extends StatelessWidget {
  const ConsentCard({
    super.key,
    required this.consent,
    required this.onReadPolicy,
  });

  final ConsentState consent;
  final VoidCallback onReadPolicy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DetailSection(
      title: 'Consentimiento',
      icon: Icons.verified_user_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(consentSummary(consent), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            'Tu nombre, correo, celular y documento se corrigen en Mi perfil.',
            style: theme.textTheme.bodySmall,
          ),
          TextButton(
            onPressed: onReadPolicy,
            child: const Text('Leer la política'),
          ),
        ],
      ),
    );
  }
}

/// Revocar el consentimiento y suprimir la cuenta (Ley 1581, art. 8). Cada
/// botón abre su hoja, que dice qué pasa y pide la contraseña.
class DataRightsCard extends StatelessWidget {
  const DataRightsCard({
    super.key,
    required this.onRevoke,
    required this.onDelete,
  });

  final VoidCallback onRevoke;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger = theme.colorScheme.error;
    const size = Size.fromHeight(48);
    return DetailSection(
      title: 'Tus derechos',
      icon: Icons.gavel_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Puedes retirar tu permiso o pedir que borremos tu cuenta.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRevoke,
            style: OutlinedButton.styleFrom(minimumSize: size),
            child: const Text('Revocar consentimiento'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onDelete,
            style: OutlinedButton.styleFrom(
              minimumSize: size,
              foregroundColor: danger,
            ),
            child: const Text('Suprimir mi cuenta'),
          ),
        ],
      ),
    );
  }
}
