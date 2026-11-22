import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_icons.dart';
import 'settings_page.dart';
import 'settings_switch.dart';

class SettingsReading extends StatelessWidget {
  const SettingsReading({super.key, required this.page});
  final SettingsPage page;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Column(
      children: [
        SettingsSwitch(
          title: 'Alto contraste',
          subtitle: 'Texto y bordes más marcados',
          icon: page.workLayout ? AppIcons.accessibility : null,
          value: page.settings.highContrast,
          onChanged: page.actions.onContrast,
        ),
        const Divider(height: 1),
        SettingsSwitch(
          title: 'Reducir movimiento',
          subtitle: 'Sin animaciones ni recorridos',
          icon: page.workLayout ? AppIcons.health : null,
          value: page.settings.reduceMotion,
          onChanged: page.actions.onMotion,
        ),
        if (page.requester) ...[
          const Divider(height: 1),
          SettingsSwitch(
            title: 'Modo sencillo',
            subtitle: 'Botones grandes y menos opciones',
            value: page.settings.simpleMode,
            onChanged: page.actions.onSimpleMode,
          ),
        ],
      ],
    ),
  );
}
