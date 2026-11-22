import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/content_page.dart';
import '../../../theme/app_icons.dart';
import '../../home/presentation/widgets/home_status_card.dart';
import 'widgets/drone_form/drone_form_page.dart';
import 'widgets/drone_form/drone_form_header.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../../hubs/data/hub_models.dart';
import '../data/fleet_models.dart';
import '../data/fleet_providers.dart';
import 'widgets/drone_form_values.dart';
import '../../../core/widgets/skeleton.dart';

/// Alta de dron (`/fleet/new`).
///
/// La central no se elige acá: es la que el operador tenía elegida en la
/// flota, la misma que viaja como `hubId`, y va en el subtítulo. La flota
/// solo ofrece "Nuevo dron" con la central activa.
class DroneFormScreen extends ConsumerStatefulWidget {
  const DroneFormScreen({super.key});

  @override
  ConsumerState<DroneFormScreen> createState() => _DroneFormScreenState();
}

class _DroneFormScreenState extends ConsumerState<DroneFormScreen> {
  final _values = DroneFormValues();
  String? _identifierError;
  String? _modelError;
  int _shakeCount = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _values.dispose();
    super.dispose();
  }

  Future<void> _submit(Hub hub) async {
    final identifierError = Validators.droneIdentifier(_values.identifier.text);
    final modelError = _values.hasModel ? null : 'Elige un modelo de dron.';
    setState(() {
      _identifierError = identifierError;
      _modelError = modelError;
      if (identifierError != null || modelError != null) _shakeCount++;
    });
    if (identifierError != null || modelError != null) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await ref
          .read(createDroneProvider.notifier)
          .create(_values.request(hub.id));
      if (!mounted) return;
      showAppSnack(context, 'Dron agregado a ${hub.name}.');
      SectionHeader.backOrHome(context);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hubs = ref.watch(assignedHubsProvider);
    final hub = ref.watch(effectiveHubProvider);
    final models = ref.watch(fleetModelsProvider);
    final waiting = !hubs.hasValue && !hubs.hasError;
    final problem = hubs.hasError && hubs.value == null
        ? ApiException.messageOf(hubs.error!)
        : hub == null && !waiting
        ? 'No tienes centrales asignadas.'
        : models.hasError && models.value == null
        ? ApiException.messageOf(models.error!)
        : models.value?.isEmpty == true
        ? 'No hay modelos de dron disponibles.'
        : null;
    if (waiting || hub == null || models.value == null || problem != null) {
      return ContentPage(
        header: DroneFormHeader(
          hubName: hub?.name ?? 'Drones de tus centrales',
          onBack: () => SectionHeader.backOrHome(context),
        ),
        title: 'Nuevo dron',
        subtitle: hub?.name ?? 'Drones de tus centrales',
        onBack: () => SectionHeader.backOrHome(context),
        slivers: [
          SliverToBoxAdapter(
            child: problem == null
                ? const SkeletonDetail()
                : HomeStatusCard(
                    title: 'No pudimos abrir el formulario',
                    message: problem,
                    icon: AppIcons.drone,
                    action: TextButton(
                      onPressed: () {
                        ref.invalidate(assignedHubsProvider);
                        ref.invalidate(fleetModelsProvider);
                      },
                      child: const Text('Reintentar'),
                    ),
                  ),
          ),
        ],
      );
    }
    return _form(hub, models.value!);
  }

  Widget _form(Hub hub, List<DroneModel> models) {
    if (models.length == 1) {
      _values.droneModelId ??= models.single.id;
    }
    return DroneFormPage(
      hubName: hub.name,
      active: hub.isActive,
      models: models,
      identifier: _values.identifier,
      selectedId: _values.droneModelId,
      cold: _values.coldCompartment,
      loading: _isLoading,
      shakeCount: _shakeCount,
      identifierError: _identifierError,
      modelError: _modelError,
      onModel: (id) => setState(() {
        _values.droneModelId = id;
        _modelError = null;
      }),
      onCold: (value) => setState(() => _values.coldCompartment = value),
      onBack: () => SectionHeader.backOrHome(context),
      onSubmit: hub.isActive ? () => _submit(hub) : null,
    );
  }
}
