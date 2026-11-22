import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/compact_form_header.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../auth/data/auth_models.dart';
import '../../../home/presentation/widgets/section_header.dart';
import '../../data/app_settings.dart';
import 'settings_actions.dart';
import 'settings_sections.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.picked,
    required this.role,
    required this.actions,
  });
  final AppSettings settings;
  final ThemeMode picked;
  final UserRole? role;
  final SettingsActions actions;
  bool get workLayout =>
      role == UserRole.dispatcher || role == UserRole.fleetOperator;
  bool get requester => role == UserRole.requester;
  @override
  Widget build(BuildContext context) {
    final content = SettingsSections(page: this);
    if (workLayout) {
      return ContentPage(
        title: 'Ajustes de la app',
        subtitle: 'Se guardan en este teléfono.',
        header: CompactFormHeader(
          title: 'Ajustes de la app',
          subtitle: 'Se guardan en este teléfono.',
          onBack: () => context.canPop()
              ? context.pop()
              : context.go(
                  role == UserRole.fleetOperator ? '/profile' : '/more',
                ),
        ),
        slivers: [SliverToBoxAdapter(child: content)],
      );
    }
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
          content,
        ],
      ),
    );
  }
}
