import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/field_limits.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/form_sheet_card.dart';
import '../../../core/widgets/message_view.dart';
import '../../auth/presentation/widgets/auth_field.dart';
import '../../auth/presentation/widgets/auth_morph_button.dart';
import '../../home/presentation/widgets/section_form_page.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../../hubs/data/hub_models.dart';
import '../data/fleet_models.dart';
import '../data/fleet_providers.dart';
import 'widgets/drone_form_values.dart';
import 'widgets/drone_model_field.dart';

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
    final hub = ref.watch(effectiveHubProvider);
    final models = ref.watch(fleetModelsProvider);
    final header = SectionHeader(
      title: 'Nuevo dron',
      subtitle: hub == null ? 'Para tu central' : 'Para ${hub.name}',
      onBack: () => SectionHeader.backOrHome(context),
    );
    final message = switch (models) {
      _ when hub == null => 'No tienes centrales asignadas.',
      AsyncValue(hasValue: true, hasError: false, :final value?) when value.isEmpty =>
        'No hay modelos de dron disponibles.',
      AsyncError(:final error) => ApiException.messageOf(error),
      _ => null,
    };
    if (message != null || models.value == null) {
      return SectionStatePage(
        header: header,
        body: message == null
            ? const Center(child: CircularProgressIndicator())
            : MessageView(icon: Icons.flight_rounded, message: message),
      );
    }
    return _form(header, hub!, models.value!);
  }

  Widget _form(Widget header, Hub hub, List<DroneModel> models) {
    // Con un solo modelo sembrado (Wingcopter 198) no hay nada que elegir.
    if (models.length == 1) _values.droneModelId ??= models.single.id;
    return SectionFormPage(
      header: header,
      card: FormSheetCard(
        children: [
          AuthField(
            label: 'Identificador',
            hint: 'D-07',
            controller: _values.identifier,
            maxLength: FieldLimits.droneIdentifier,
            errorText: _identifierError,
            shakeCount: _shakeCount,
          ),
          const SizedBox(height: 16),
          DroneModelField(
            models: models,
            selectedId: _values.droneModelId,
            errorText: _modelError,
            shakeCount: _shakeCount,
            onChanged: (id) => setState(() {
              _values.droneModelId = id;
              _modelError = null;
            }),
          ),
        ],
      ),
      button: AuthMorphButton(
        label: 'Agregar dron',
        loadingLabel: 'Agregando el dron',
        isLoading: _isLoading,
        onPressed: hub.isActive ? () => _submit(hub) : null,
      ),
    );
  }
}
