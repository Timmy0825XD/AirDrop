import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../home/presentation/widgets/section_header.dart';
import '../data/privacy_providers.dart';
import 'widgets/privacy/policy_content.dart';

/// La política de tratamiento de datos (`/privacy/policy`, RF-50). Se lee
/// con o sin sesión: la abren el registro y "Mis datos".
class PolicyScreen extends ConsumerWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(policyProvider);
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Política de datos',
            subtitle: policySubtitle(policy.value),
            // Sin sesión no hay inicio: se vuelve al registro o al login.
            onBack: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          Expanded(
            child: PolicyBody(
              policy: policy,
              onRetry: () => ref.invalidate(policyProvider),
            ),
          ),
        ],
      ),
    );
  }
}
