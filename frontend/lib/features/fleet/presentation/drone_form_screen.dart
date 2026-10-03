import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/error_banner.dart';
import '../../hubs/data/hub_models.dart';
import '../data/fleet_models.dart';
import '../data/fleet_providers.dart';
import 'widgets/drone_form_content.dart';
import 'widgets/drone_form_values.dart';

/// Alta de dron (`/fleet/new`).
///
/// La central no se elige acá: es la que el operador tenía elegida en la
/// pantalla de flota, la misma que viaja como `hubId`. Si esa central
/// está suspendida el formulario queda visible pero el botón se apaga,
/// con el mensaje que Nest devolvería (`La central está suspendida.`).
class DroneFormScreen extends ConsumerStatefulWidget {
  const DroneFormScreen({super.key});

  @override
  ConsumerState<DroneFormScreen> createState() => _DroneFormScreenState();
}

class _DroneFormScreenState extends ConsumerState<DroneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _values = DroneFormValues();
  bool _isLoading = false;
  String? _modelError;

  @override
  void dispose() {
    _values.dispose();
    super.dispose();
  }

  Future<void> _submit(String hubId) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_values.hasModel) {
      setState(() => _modelError = 'Selecciona un modelo de dron.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await _createDrone(context, ref, hubId, _values);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hubs = ref.watch(assignedHubsProvider);

    // Sin central no hay formulario: `POST /fleet/drones` exige `hubId`.
    return hubs.when(
      loading: _spinnerScaffold,
      error: (error, _) => _statusScaffold('$error'),
      data: (rows) {
        final hub = ref.watch(effectiveHubProvider);
        if (hub == null) {
          return _statusScaffold('No tienes centrales asignadas.');
        }
        final models = ref.watch(fleetModelsProvider);
        return models.when(
          loading: _spinnerScaffold,
          error: (error, _) => _statusScaffold('$error'),
          data: (modelRows) => modelRows.isEmpty
              ? _statusScaffold('No hay modelos de dron disponibles.')
              : _formScaffold(hub, modelRows),
        );
      },
    );
  }

  Scaffold _formScaffold(Hub hub, List<DroneModel> models) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo dron')),
      body: Column(
        children: [
          if (!hub.isActive)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ErrorBanner(message: 'La central está suspendida.'),
            ),
          Expanded(
            child: DroneFormContent(
              formKey: _formKey,
              values: _values,
              models: models,
              hub: hub,
              modelError: _modelError,
              onModelChanged: (id) => setState(() {
                _values.droneModelId = id;
                _modelError = null;
              }),
              onSubmit: () => _submit(hub.id),
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Scaffold _spinnerScaffold() {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Scaffold _statusScaffold(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo dron')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// `POST /fleet/drones` y vuelta a la flota. Los mensajes de error son
/// los de Nest (`Ya existe un dron con este identificador.`,
/// `El modelo de dron no existe.`, `La central está suspendida.`); aquí
/// no se sustituyen por textos genéricos.
Future<void> _createDrone(
  BuildContext context,
  WidgetRef ref,
  String hubId,
  DroneFormValues values,
) async {
  try {
    await ref
        .read(createDroneProvider.notifier)
        .create(values.request(hubId));
    if (!context.mounted) return;
    showAppSnack(context, 'Dron agregado a la flota.');
    context.go('/fleet');
  } on ApiException catch (error) {
    if (context.mounted) showAppSnack(context, error.message);
  }
}
