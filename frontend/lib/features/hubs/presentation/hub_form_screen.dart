import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../auth/presentation/widgets/auth_morph_button.dart';
import '../../home/presentation/widgets/section_form_page.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/hub_models.dart';
import '../data/hub_providers.dart';
import 'widgets/hub_form/hub_form_sheet.dart';
import 'widgets/hub_form_values.dart';

/// Alta y edición de central, solo del administrador. El alta
/// (`POST /hubs`) nace `active`: Nest no tiene etapa de aprobación. Con
/// [hubId] se edita (`PATCH /hubs/:id`) mandando solo lo que cambió. La
/// ubicación se toca en el mapa en vez de escribir latitud y longitud.
class HubFormScreen extends ConsumerStatefulWidget {
  const HubFormScreen({super.key, this.hubId});

  /// La central que se edita; `null` para una nueva.
  final String? hubId;

  @override
  ConsumerState<HubFormScreen> createState() => _HubFormScreenState();
}

class _HubFormScreenState extends ConsumerState<HubFormScreen> {
  final _values = HubFormValues();
  Map<HubInput, String> _errors = const {};
  int _shakeCount = 0;
  bool _isLoading = false;
  Hub? _original;

  @override
  void dispose() {
    _values.dispose();
    super.dispose();
  }

  /// La central que se edita, cargada una vez en el formulario.
  Hub? _editing() {
    final id = widget.hubId;
    if (id == null) return null;
    final hubs = ref.watch(allHubsProvider).value;
    final hub = hubs?.where((h) => h.id == id).firstOrNull;
    if (hub != null && _original == null) {
      _original = hub;
      _values.load(hub);
    }
    return _original;
  }

  Future<void> _submit() async {
    final errors = _values.validate();
    setState(() {
      _errors = errors;
      if (errors.isNotEmpty) _shakeCount++;
    });
    if (errors.isNotEmpty) return;
    final original = _original;
    final changes = original == null ? null : _values.changes(original);
    if (changes != null && changes.isEmpty) {
      showAppSnack(
        context,
        'No hay cambios para guardar.',
        tone: SnackTone.info,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      if (original == null) {
        await ref.read(createHubProvider.notifier).create(_values.request());
      } else {
        await ref.read(updateHubProvider.notifier).edit(original.id, changes!);
      }
      if (!mounted) return;
      showAppSnack(
        context,
        original == null
            ? 'Central creada. Ya está activa.'
            : 'Central actualizada.',
      );
      context.go('/hubs');
    } on ApiException catch (error) {
      // Mover con vuelos en curso (409) o a una geovalla (400): el resto
      // de los datos se puede seguir editando.
      if (mounted) showErrorSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.hubId != null;
    final hub = _editing();
    return SectionFormPage(
      header: SectionHeader(
        title: editing ? 'Editar central' : 'Nueva central',
        subtitle: editing
            ? hub?.name ?? 'Cargando la central'
            : 'Nace activa y lista para operar.',
        onBack: () => context.go('/hubs'),
      ),
      card: editing && hub == null
          ? const Center(child: CircularProgressIndicator())
          : HubFormSheet(
              values: _values,
              errors: _errors,
              shakeCount: _shakeCount,
              onChanged: () => setState(() {}),
            ),
      button: AuthMorphButton(
        label: editing ? 'Guardar cambios' : 'Crear central',
        loadingLabel: editing ? 'Guardando la central' : 'Creando la central',
        isLoading: _isLoading,
        onPressed: editing && hub == null ? null : _submit,
      ),
    );
  }
}
