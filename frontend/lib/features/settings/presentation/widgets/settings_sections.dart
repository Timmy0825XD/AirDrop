import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/choice_pill.dart';
import '../../../../core/widgets/menu_list.dart';
import '../../../../core/widgets/sliding_segmented.dart';
import '../../../../theme/app_icons.dart';
import '../../../home/presentation/widgets/home_grid.dart';
import '../../../home/presentation/widgets/home_section_heading.dart';
import '../../data/app_settings.dart';
import 'settings_page.dart';
import 'settings_reading.dart';
import 'theme_picker.dart';

class SettingsSections extends StatelessWidget {
  const SettingsSections({super.key, required this.page});
  final SettingsPage page;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SettingsBlock(
        label: 'Tema',
        inset: !page.workLayout,
        child: ThemePicker(
          applied: page.settings.themeMode,
          picked: page.picked,
          onPick: page.actions.onPick,
          onApply: page.actions.onApply,
        ),
      ),
      SettingsBlock(
        label: 'Tamaño del texto',
        inset: !page.workLayout,
        child: _TextSizeChoice(page: page),
      ),
      SettingsBlock(
        label: 'Lectura y movimiento',
        inset: !page.workLayout,
        child: SettingsReading(page: page),
      ),
      if (page.requester)
        SettingsBlock(
          label: 'Ayuda',
          child: MenuList(
            items: [
              MenuItem(
                title: 'Ver la bienvenida',
                subtitle: 'Cómo funciona AirDrop, en tres pasos',
                icon: AppIcons.info,
                onTap: () => context.push('/welcome'),
              ),
            ],
          ),
        ),
    ],
  );
}

class SettingsBlock extends StatelessWidget {
  const SettingsBlock({
    super.key,
    required this.label,
    required this.child,
    this.inset = true,
  });
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

class _TextSizeChoice extends StatelessWidget {
  const _TextSizeChoice({required this.page});
  final SettingsPage page;
  @override
  Widget build(BuildContext context) => page.workLayout
      ? Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final size in TextSize.values)
              ChoicePill(
                label: size.label,
                selected: size == page.settings.textSize,
                onTap: () => page.actions.onTextSize(size),
              ),
          ],
        )
      : SlidingSegmented<TextSize>(
          options: [
            for (final size in TextSize.values) SegmentOption(size, size.label),
          ],
          selected: page.settings.textSize,
          onChanged: page.actions.onTextSize,
        );
}
