import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_models.dart';
import '../../hubs/data/hub_providers.dart';
import 'widgets/home_shell.dart';
import 'dispatcher_cards.dart';

class DispatcherHome extends ConsumerWidget {
  const DispatcherHome({super.key, required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HomeShell(
      user: user,
      body: _DispatcherBody(user: user),
    );
  }
}

class _DispatcherBody extends ConsumerWidget {
  const _DispatcherBody({required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(myHubProvider);
    return hub.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          DispatcherCards(hub: null, errorMessage: error.toString()),
      data: (value) => DispatcherCards(hub: value),
    );
  }
}
