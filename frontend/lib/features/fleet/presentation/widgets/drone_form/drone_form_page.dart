import 'package:flutter/material.dart';
import '../../../../../core/widgets/content_page.dart';
import '../../../../../core/widgets/form_submit_button.dart';
import '../../../../../core/widgets/warning_banner.dart';
import '../../../data/fleet_models.dart';
import '../drone_model_field.dart';
import 'cold_compartment_switch.dart';
import 'drone_identifier_field.dart';
import 'drone_form_header.dart';
import '../../../../../theme/app_icons.dart';

class DroneFormPage extends StatelessWidget {
  const DroneFormPage({
    super.key,
    required this.hubName,
    required this.active,
    required this.identifier,
    required this.models,
    required this.selectedId,
    required this.cold,
    required this.loading,
    required this.onModel,
    required this.onCold,
    required this.onBack,
    required this.onSubmit,
    required this.shakeCount,
    this.identifierError,
    this.modelError,
  });
  final String hubName;
  final bool active, cold, loading;
  final TextEditingController identifier;
  final List<DroneModel> models;
  final String? selectedId, identifierError, modelError;
  final int shakeCount;
  final ValueChanged<String> onModel;
  final ValueChanged<bool> onCold;
  final VoidCallback onBack;
  final VoidCallback? onSubmit;
  @override
  Widget build(BuildContext context) => ContentPage(
    header: DroneFormHeader(hubName: hubName, onBack: onBack),
    title: 'Nuevo dron',
    subtitle: hubName,
    onBack: onBack,
    slivers: [SliverToBoxAdapter(child: _DroneFormFields(page: this))],
  );
}

class _DroneFormFields extends StatelessWidget {
  const _DroneFormFields({required this.page});
  final DroneFormPage page;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (!page.active)
        const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: WarningBanner(
            message: 'La central está suspendida. No puedes agregar drones.',
          ),
        ),
      _DroneIdentity(page: page),
      const SizedBox(height: 24),
      _DroneModelChoice(page: page),
      const SizedBox(height: 24),
      _DroneEquipment(page: page),
      const SizedBox(height: 28),
      FormSubmitButton(
        label: 'Agregar dron',
        loadingLabel: 'Agregando el dron',
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        loading: page.loading,
        onPressed: page.active ? page.onSubmit : null,
      ),
    ],
  );
}

class _DroneIdentity extends StatelessWidget {
  const _DroneIdentity({required this.page});
  final DroneFormPage page;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Identificación', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      DroneIdentifierField(
        controller: page.identifier,
        errorText: page.identifierError,
        shakeCount: page.shakeCount,
      ),
    ],
  );
}

class _DroneModelChoice extends StatelessWidget {
  const _DroneModelChoice({required this.page});
  final DroneFormPage page;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Modelo', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      DroneModelField(
        models: page.models,
        selectedId: page.selectedId,
        onChanged: page.onModel,
        coldCompartment: page.cold,
        errorText: page.modelError,
        shakeCount: page.shakeCount,
      ),
    ],
  );
}

class _DroneEquipment extends StatelessWidget {
  const _DroneEquipment({required this.page});
  final DroneFormPage page;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Equipamiento', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      ColdCompartmentSwitch(value: page.cold, onChanged: page.onCold),
      const SizedBox(height: 12),
      Row(
        children: [
          const Icon(AppIcons.info, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Resta 1 kg de carga útil.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
      const Divider(height: 28),
      _PayloadNote(page: page),
    ],
  );
}

class _PayloadNote extends StatelessWidget {
  const _PayloadNote({required this.page});
  final DroneFormPage page;
  @override
  Widget build(BuildContext context) {
    final model = page.models.where((m) => m.id == page.selectedId).firstOrNull;
    final text = model == null
        ? 'Elige un modelo para ver la carga útil.'
        : 'Carga útil disponible: ${model.payloadKg(coldCompartment: page.cold).toStringAsFixed(0)} kg';
    return Row(
      children: [
        const Icon(AppIcons.orders, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleSmall),
        ),
      ],
    );
  }
}
