import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_models.dart';
import 'widgets/home_action_card.dart';
import 'widgets/home_shell.dart';
import 'widgets/module_preview.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key, required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context) {
    return HomeShell(
      user: user,
      body: Column(
        children: [
          HomeActionCard(
            title: 'Centrales',
            subtitle: 'Crea, revisa y suspende centrales operativas.',
            icon: Icons.home_work_outlined,
            onTap: () => context.go('/hubs'),
          ),
          const SizedBox(height: 12),
          HomeActionCard(
            title: 'Cuentas institucionales',
            subtitle: 'Gestiona despachadores y operadores.',
            icon: Icons.groups_outlined,
            onTap: () => showModulePreview(context, 'Cuentas institucionales'),
          ),
        ],
      ),
    );
  }
}
