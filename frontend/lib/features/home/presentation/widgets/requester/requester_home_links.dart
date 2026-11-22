import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../theme/app_icons.dart';
import '../home_link.dart';
import '../home_section_heading.dart';

class RequesterHomeLinks extends StatelessWidget {
  const RequesterHomeLinks({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const HomeSectionHeading(title: 'Explora'),
      HomeLink(
        icon: AppIcons.medication,
        title: 'Medicamentos disponibles',
        onTap: () => context.push('/medications'),
      ),
      const SizedBox(height: 10),
      HomeLink(
        icon: AppIcons.plans,
        title: 'Crear entrega periódica',
        subtitle: 'Programa tus próximas entregas',
        onTap: () => context.push('/orders/plans/new'),
      ),
    ],
  );
}
