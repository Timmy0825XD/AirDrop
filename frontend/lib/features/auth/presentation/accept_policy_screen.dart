import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/auth_morph_button.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../../home/presentation/widgets/sign_out.dart';
import '../data/privacy_providers.dart';
import 'auth_controller.dart';
import 'widgets/privacy/policy_content.dart';

/// Aceptar la política vigente (`/privacy/accept`, RF-50). El router trae
/// aquí al solicitante con `mustAcceptPolicy`: sin aceptar, Nest responde
/// 403 al pedir. Al aceptar se relee la cuenta y el router sigue al inicio.
class AcceptPolicyScreen extends ConsumerStatefulWidget {
  const AcceptPolicyScreen({super.key});

  @override
  ConsumerState<AcceptPolicyScreen> createState() => _AcceptPolicyScreenState();
}

class _AcceptPolicyScreenState extends ConsumerState<AcceptPolicyScreen> {
  bool _sending = false;

  Future<void> _accept(String version) async {
    setState(() => _sending = true);
    try {
      await ref.read(authControllerProvider.notifier).acceptPolicy(version);
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.message);
      // Si cambió la versión, se vuelve a leer la política.
      ref.invalidate(policyProvider);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final policy = ref.watch(policyProvider);
    final version = policy.value?.version;
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Actualizamos la política de datos',
            subtitle: 'Léela y acéptala para seguir pidiendo',
            onBack: () => signOut(context, ref),
          ),
          Expanded(
            child: PolicyBody(
              policy: policy,
              onRetry: () => ref.invalidate(policyProvider),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AuthMorphButton(
              label: 'Acepto la política',
              loadingLabel: 'Guardando',
              isLoading: _sending,
              onPressed: version == null ? null : () => _accept(version),
            ),
          ),
        ],
      ),
    );
  }
}
