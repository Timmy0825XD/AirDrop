import 'package:flutter/material.dart';

import '../../../../../theme/app_icons.dart';
import '../home_link.dart';
import '../home_section_heading.dart';

class DispatcherHomeLinks extends StatelessWidget {
  const DispatcherHomeLinks({
    super.key,
    required this.active,
    required this.hasHub,
    required this.onOpen,
  });
  final bool active, hasHub;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const HomeSectionHeading(title: 'Tu central y abastecimientos'),
      HomeLink(
        title: 'Mi central',
        subtitle: 'Consulta sus datos y estado',
        icon: AppIcons.hub,
        onTap: hasHub ? () => onOpen('/hubs/me') : null,
      ),
      const SizedBox(height: 10),
      HomeLink(
        title: 'Urgencia a otra central',
        subtitle: 'Solicita un insumo que necesitas',
        icon: AppIcons.transfer,
        onTap: active ? () => onOpen('/orders/hub-emergency') : null,
      ),
      const SizedBox(height: 10),
      HomeLink(
        title: 'Nuevo abastecimiento',
        subtitle: 'Programa entregas a tu central',
        icon: AppIcons.createPlan,
        onTap: active ? () => onOpen('/orders/hub-plans/new') : null,
      ),
      const SizedBox(height: 10),
      HomeLink(
        title: 'Mis abastecimientos',
        subtitle: 'Consulta tus entregas periódicas',
        icon: AppIcons.plans,
        onTap: () => onOpen('/orders/plans'),
      ),
    ],
  );
}
