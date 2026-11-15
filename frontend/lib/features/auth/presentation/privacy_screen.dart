import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/list_padding.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/skeleton.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/privacy_models.dart';
import '../data/privacy_providers.dart';
import 'auth_controller.dart';
import 'widgets/privacy/password_confirm_sheet.dart';
import 'widgets/privacy/privacy_cards.dart';

/// "Mis datos" (`/privacy`, CU-46), solo del solicitante: qué política
/// aceptó, y revocar el consentimiento o suprimir la cuenta (RF-50). Las
/// dos acciones piden la contraseña y cierran la sesión en este teléfono.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  static const revokedMessage =
      'Revocaste el consentimiento: tu cuenta está inactiva.';
  static const deletedMessage = 'Tu cuenta se suprimió.';

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    PrivacyOverview overview,
  ) async {
    final password = await showPasswordConfirmSheet(
      context,
      title: '¿Revocar el consentimiento?',
      notices: overview.revokeNotice,
      confirmLabel: 'Revocar',
    );
    if (password == null || !context.mounted) return;
    final auth = ref.read(authControllerProvider.notifier);
    try {
      await auth.revokeConsent(password);
      if (!context.mounted) return;
      showAppSnack(context, revokedMessage, tone: SnackTone.info);
      await auth.endSession();
    } on ApiException catch (e) {
      if (context.mounted) showErrorSnack(context, e.message);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PrivacyOverview overview,
  ) async {
    final password = await showPasswordConfirmSheet(
      context,
      title: '¿Suprimir tu cuenta?',
      notices: overview.suppressNotice,
      confirmLabel: 'Suprimir mi cuenta',
    );
    if (password == null || !context.mounted) return;
    final auth = ref.read(authControllerProvider.notifier);
    final router = GoRouter.of(context);
    try {
      // Con un pedido en curso Nest responde 409 y la sesión sigue.
      await auth.deleteAccount(password);
      if (!context.mounted) return;
      showAppSnack(context, deletedMessage, tone: SnackTone.info);
      await auth.endSession();
      router.go('/register');
    } on ApiException catch (e) {
      if (context.mounted) showErrorSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(privacyOverviewProvider);
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Mis datos',
            subtitle: 'Tu consentimiento y tus derechos',
            onBack: () => SectionHeader.backOrHome(context),
          ),
          Expanded(
            child: switch (overview) {
              AsyncValue(hasValue: true, :final value?) => ListView(
                padding: listPadding(context, top: 8),
                children: [
                  ConsentCard(
                    consent: value.consent,
                    onReadPolicy: () => context.push('/privacy/policy'),
                  ),
                  const SizedBox(height: 12),
                  DataRightsCard(
                    onRevoke: () => _revoke(context, ref, value),
                    onDelete: () => _delete(context, ref, value),
                  ),
                ],
              ),
              AsyncError(:final error) => MessageView.error(
                message: ApiException.messageOf(error),
                action: OutlinedButton(
                  onPressed: () => ref.invalidate(privacyOverviewProvider),
                  child: const Text('Reintentar'),
                ),
              ),
              _ => const SkeletonDetail(),
            },
          ),
        ],
      ),
    );
  }
}
