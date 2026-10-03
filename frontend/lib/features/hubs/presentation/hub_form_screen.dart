import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../data/hub_models.dart';
import '../data/hub_providers.dart';
import 'widgets/hub_form_content.dart';
import 'widgets/hub_form_values.dart';

/// Alta de central, solo del administrador (`POST /hubs`). La central nace
/// `active`: Nest no tiene etapa de aprobación.
class HubFormScreen extends ConsumerStatefulWidget {
  const HubFormScreen({super.key});

  @override
  ConsumerState<HubFormScreen> createState() => _HubFormScreenState();
}

class _HubFormScreenState extends ConsumerState<HubFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _values = HubFormValues();
  HubType _type = HubType.hospital;
  bool _isLoading = false;

  @override
  void dispose() {
    _values.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await ref.read(createHubProvider.notifier).create(_values.request(_type));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva central')),
      body: HubFormContent(
        formKey: _formKey,
        values: _values,
        type: _type,
        onTypeChanged: (value) => setState(() => _type = value ?? HubType.hospital),
        onSubmit: _submit,
        isLoading: _isLoading,
      ),
    );
  }
}
