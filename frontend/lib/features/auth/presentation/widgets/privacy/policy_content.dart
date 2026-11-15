import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api_exception.dart';
import '../../../../../core/date_format.dart';
import '../../../../../core/widgets/message_view.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../data/privacy_models.dart';

/// "Versión 1.0 · rige desde el sáb. 14 nov."
String policySubtitle(PrivacyPolicy? policy) => policy == null
    ? 'Tratamiento de datos personales'
    : 'Versión ${policy.version} · rige desde el '
          '${formatDay(policy.effectiveFrom, relative: false)}';

/// La política según cómo va su carga: el texto, el esqueleto o el error
/// de Nest con "Reintentar".
class PolicyBody extends StatelessWidget {
  const PolicyBody({super.key, required this.policy, required this.onRetry});

  final AsyncValue<PrivacyPolicy> policy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => switch (policy) {
    AsyncValue(hasValue: true, :final value?) => PolicyContent(policy: value),
    AsyncError(:final error) => MessageView.error(
      message: ApiException.messageOf(error),
      action: OutlinedButton(
        onPressed: onRetry,
        child: const Text('Reintentar'),
      ),
    ),
    _ => const SkeletonDetail(),
  };
}

/// El texto de la política: cada apartado con su título y sus párrafos, y
/// al final a quién escribirle.
class PolicyContent extends StatelessWidget {
  const PolicyContent({super.key, required this.policy});

  final PrivacyPolicy policy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium?.copyWith(height: 1.5);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        for (final section in policy.sections) ...[
          Text(section.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          for (final line in section.body)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(line, style: body),
            ),
          const SizedBox(height: 12),
        ],
        if (policy.contactEmail.isNotEmpty)
          SelectableText(
            'Responsable: ${policy.controllerName}. '
            'Escríbenos a ${policy.contactEmail}.',
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}
