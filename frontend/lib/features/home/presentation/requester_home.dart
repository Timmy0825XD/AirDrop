import 'package:flutter/material.dart';

import '../../auth/data/auth_models.dart';
import 'widgets/home_info_card.dart';
import 'widgets/home_shell.dart';

class RequesterHome extends StatelessWidget {
  const RequesterHome({super.key, required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context) {
    return HomeShell(
      user: user,
      body: const HomeInfoCard(
        title: 'Pedidos aún no disponibles',
        subtitle: 'La función de pedidos estará disponible más adelante.',
        icon: Icons.local_shipping_outlined,
      ),
    );
  }
}
