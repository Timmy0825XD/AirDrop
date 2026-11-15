import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/menu_list.dart';
import '../../../core/widgets/sliding_segmented.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../home/presentation/widgets/home_grid.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/app_settings.dart';
import 'widgets/settings_switch.dart';
import 'widgets/theme_picker.dart';

/// Ajustes (RF-52, CU-50), para cualquier rol: tema con vista previa,
/// tamaño del texto, alto contraste y reducir movimiento. El solicitante
/// tiene además el modo sencillo y puede volver a ver la bienvenida. Todo
/// se guarda en el teléfono. El tema espera a "Aplicar"; lo demás se
/// aplica al tocarlo.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// El tema que se mira en la vista previa; `null` es el aplicado.
  ThemeMode? _picked;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final control = ref.read(settingsProvider.notifier);
    final role = ref.watch(authControllerProvider).value?.user?.role;
    final requester = role == UserRole.requester;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          SectionHeader(
            title: 'Ajustes',
            subtitle: 'Se guardan en este teléfono',
            onBack: () => SectionHeader.backOrHome(context),
          ),
          _Block(
            label: 'Tema',
            child: ThemePicker(
              applied: settings.themeMode,
              picked: _picked ?? settings.themeMode,
              onPick: (mode) => setState(() => _picked = mode),
              onApply: () {
                control.setThemeMode(_picked!);
                setState(() => _picked = null);
              },
            ),
          ),
          _Block(
            label: 'Tamaño del texto',
            child: SlidingSegmented<TextSize>(
              options: [
                for (final size in TextSize.values)
                  SegmentOption(size, size.label),
              ],
              selected: settings.textSize,
              onChanged: control.setTextSize,
            ),
          ),
          _Block(
            label: 'Lectura y movimiento',
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: [
                  SettingsSwitch(
                    title: 'Alto contraste',
                    subtitle: 'Texto y bordes más marcados',
                    value: settings.highContrast,
                    onChanged: control.setHighContrast,
                  ),
                  SettingsSwitch(
                    title: 'Reducir movimiento',
                    subtitle: 'Sin animaciones ni recorridos',
                    value: settings.reduceMotion,
                    onChanged: control.setReduceMotion,
                  ),
                  if (requester)
                    SettingsSwitch(
                      title: 'Modo sencillo',
                      subtitle: 'Botones grandes y menos opciones',
                      value: settings.simpleMode,
                      onChanged: control.setSimpleMode,
                    ),
                ],
              ),
            ),
          ),
          if (requester)
            _Block(
              label: 'Ayuda',
              child: MenuList(
                items: [
                  MenuItem(
                    title: 'Ver la bienvenida',
                    subtitle: 'Cómo funciona AirDrop, en tres pasos',
                    icon: Icons.help_outline_rounded,
                    onTap: () => context.push('/welcome'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Un grupo de ajustes: el rótulo y su contenido, con el margen de la app.
class _Block extends StatelessWidget {
  const _Block({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [HomeLabel(label), child],
    ),
  );
}
