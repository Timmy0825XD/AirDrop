import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/menu_list.dart';
import '../../../core/widgets/sliding_segmented.dart';
import '../../../core/widgets/content_page.dart';
import '../../home/presentation/widgets/home_section_heading.dart';
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
    final dispatcher = role == UserRole.dispatcher;
    return _SettingsPage(
      dispatcher: dispatcher,
      children: [
        if (!dispatcher)
          SectionHeader(
            title: 'Ajustes',
            subtitle: 'Se guardan en este teléfono',
            onBack: () => SectionHeader.backOrHome(context),
          ),
        _Block(
          inset: !dispatcher,
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
          inset: !dispatcher,
          label: 'Tamaño del texto',
          child: dispatcher
              ? _TextSizeChoice(
                  selected: settings.textSize,
                  onChanged: control.setTextSize,
                )
              : SlidingSegmented<TextSize>(
                  options: [
                    for (final size in TextSize.values)
                      SegmentOption(size, size.label),
                  ],
                  selected: settings.textSize,
                  onChanged: control.setTextSize,
                ),
        ),
        _Block(
          inset: !dispatcher,
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
    );
  }
}

/// Un grupo de ajustes: el rótulo y su contenido, con el margen de la app.
class _Block extends StatelessWidget {
  const _Block({required this.label, required this.child, this.inset = true});

  final String label;
  final Widget child;
  final bool inset;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      inset ? 16 : 0,
      0,
      inset ? 16 : 0,
      inset ? 4 : 28,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        inset ? HomeLabel(label) : HomeSectionHeading(title: label),
        child,
      ],
    ),
  );
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.dispatcher, required this.children});
  final bool dispatcher;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => dispatcher
      ? ContentPage(
          title: 'Ajustes de la app',
          subtitle: 'Se guardan en este teléfono.',
          onBack: () => context.canPop() ? context.pop() : context.go('/more'),
          slivers: [SliverToBoxAdapter(child: Column(children: children))],
        )
      : Scaffold(
          body: ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 24,
            ),
            children: children,
          ),
        );
}

class _TextSizeChoice extends StatelessWidget {
  const _TextSizeChoice({required this.selected, required this.onChanged});
  final TextSize selected;
  final ValueChanged<TextSize> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final size in TextSize.values)
        ChoiceChip(
          label: Text(size.label),
          selected: size == selected,
          showCheckmark: false,
          selectedColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: size == selected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
          onSelected: (_) => onChanged(size),
        ),
    ],
  );
}
