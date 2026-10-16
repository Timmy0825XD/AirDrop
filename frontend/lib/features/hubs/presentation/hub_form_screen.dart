import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/rise_in.dart';
import '../../auth/presentation/widgets/auth_morph_button.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/hub_providers.dart';
import 'widgets/hub_form/hub_form_sheet.dart';
import 'widgets/hub_form_values.dart';

/// Alta de central, solo del administrador (`POST /hubs`). La central nace
/// `active`: Nest no tiene etapa de aprobación. La ubicación se toca en el
/// mapa en vez de escribir latitud y longitud.
class HubFormScreen extends ConsumerStatefulWidget {
  const HubFormScreen({super.key});

  @override
  ConsumerState<HubFormScreen> createState() => _HubFormScreenState();
}

class _HubFormScreenState extends ConsumerState<HubFormScreen> {
  final _values = HubFormValues();
  Map<HubInput, String> _errors = const {};
  int _shakeCount = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _values.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final errors = _values.validate();
    setState(() {
      _errors = errors;
      if (errors.isNotEmpty) _shakeCount++;
    });
    if (errors.isNotEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await ref.read(createHubProvider.notifier).create(_values.request());
      if (!mounted) return;
      showAppSnack(context, 'Central creada. Ya está activa.');
      context.go('/hubs');
    } on ApiException catch (error) {
      if (mounted) showAppSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: bottom + 24),
        children: [
          SectionHeader(
            title: 'Nueva central',
            subtitle: 'Nace activa. Puedes suspenderla después.',
            onBack: () => context.go('/hubs'),
          ),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RiseIn(
                child: HubFormSheet(
                  values: _values,
                  errors: _errors,
                  shakeCount: _shakeCount,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AuthMorphButton(
              label: 'Crear central',
              loadingLabel: 'Creando la central',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
