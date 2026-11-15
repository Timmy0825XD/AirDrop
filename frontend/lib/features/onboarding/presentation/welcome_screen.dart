import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/prefs/app_prefs.dart';
import '../../../theme/app_motion.dart';
import 'welcome_steps.dart';
import 'widgets/welcome_page.dart';
import 'widgets/welcome_progress.dart';

/// La bienvenida del solicitante (RF-53, CU-51): tres pasos que explican
/// cómo funciona AirDrop. Sale sola una vez, después del primer ingreso en
/// este teléfono, y se puede volver a ver desde Ajustes. No pide datos ni
/// permisos. "Omitir" y el último "Empezar" llevan al inicio y dejan
/// anotado que ya se vio.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _pages = PageController();
  int _step = 0;

  bool get _last => _step == welcomeSteps.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(prefsStoreProvider).setBool(PrefKeys.onboardingSeen, true);
    if (mounted) context.go('/home');
  }

  void _next() {
    if (_last) {
      _finish();
      return;
    }
    final time = AppMotion.of(context, AppMotion.page);
    time == Duration.zero
        ? _pages.jumpToPage(_step + 1)
        : _pages.nextPage(duration: time, curve: AppMotion.pageCurve);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Omitir'),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _step = i),
                  children: [
                    for (final step in welcomeSteps) WelcomePage(step: step),
                  ],
                ),
              ),
              WelcomeProgress(count: welcomeSteps.length, current: _step),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(_last ? 'Empezar' : 'Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
