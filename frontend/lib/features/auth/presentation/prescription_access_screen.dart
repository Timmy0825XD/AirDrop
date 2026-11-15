import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/date_format.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/list_padding.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/skeleton.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/privacy_models.dart';
import '../data/privacy_providers.dart';
import 'widgets/profile/profile_labels.dart';

/// "Hoja 1 · Autorizar · Despachador"
String accessFacts(PrescriptionAccess access) => [
  'Hoja ${access.fileIndex + 1}',
  access.purposeLabel,
  if (access.role case final role?) ProfileLabels.role(role),
].join(' · ');

/// El registro de accesos a fórmulas (`/privacy/prescription-access`,
/// RF-51), solo del administrador: quién abrió qué fórmula, para qué y
/// cuándo, de la más reciente a la más vieja. No muestra la fórmula.
class PrescriptionAccessScreen extends ConsumerWidget {
  const PrescriptionAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(prescriptionAccessProvider);
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Accesos a fórmulas',
            subtitle: 'Quién abrió una fórmula y para qué',
            onBack: () => SectionHeader.backOrHome(context),
          ),
          Expanded(
            child: switch (log) {
              AsyncValue(hasValue: true, :final value?) when value.isEmpty =>
                const MessageView(
                  icon: Icons.fact_check_rounded,
                  title: 'Sin accesos todavía',
                  message: 'Cuando alguien abra una fórmula, queda aquí.',
                ),
              AsyncValue(hasValue: true, :final value?) => ListView.separated(
                padding: listPadding(context, top: 8),
                itemCount: value.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _AccessTile(access: value[i]),
              ),
              AsyncError(:final error) => MessageView.error(
                message: ApiException.messageOf(error),
                action: OutlinedButton(
                  onPressed: () => ref.invalidate(prescriptionAccessProvider),
                  child: const Text('Reintentar'),
                ),
              ),
              _ => const SkeletonList(),
            },
          ),
        ],
      ),
    );
  }
}

/// Un acceso: quién, qué hoja y para qué, y cuándo.
class _AccessTile extends StatelessWidget {
  const _AccessTile({required this.access});

  final PrescriptionAccess access;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            access.userName ?? 'Cuenta suprimida',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(accessFacts(access), style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            '${formatDateTime(access.accessedAt)} · '
            'Pedido ${access.shortOrderId}',
            style: muted,
          ),
        ],
      ),
    );
  }
}
