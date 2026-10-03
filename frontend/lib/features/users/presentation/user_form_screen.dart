import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../data/user_providers.dart';
import 'widgets/user_form_content.dart';
import 'widgets/user_form_values.dart';

/// Alta de cuenta institucional, solo del administrador (`POST /users`).
/// La cuenta nace `active` y sin OTP: el nuevo entra con su contraseña.
class UserFormScreen extends ConsumerStatefulWidget {
  const UserFormScreen({super.key});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _values = UserFormValues();
  bool _isLoading = false;

  @override
  void dispose() {
    _values.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    final hubError = hubSelectionError(_values.role, _values.hubIds);
    setState(() => _values.hubError = hubError);
    if (!formOk || hubError != null) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await ref.read(createUserProvider.notifier).create(_values.request());
      if (!mounted) return;
      showAppSnack(context, 'Cuenta creada. Ya está activa.');
      context.go('/users');
    } on ApiException catch (error) {
      if (mounted) showAppSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hubs = ref.watch(assignableHubsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva cuenta')),
      body: hubs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$error', textAlign: TextAlign.center),
          ),
        ),
        data: (rows) => UserFormContent(
          formKey: _formKey,
          values: _values,
          hubs: rows,
          onChanged: () => setState(() {}),
          onSubmit: _submit,
          isLoading: _isLoading,
        ),
      ),
    );
  }
}
