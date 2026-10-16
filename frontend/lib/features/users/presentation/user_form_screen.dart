import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../auth/presentation/widgets/auth_morph_button.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../../hubs/data/hub_models.dart';
import '../data/user_providers.dart';
import 'widgets/user_form/user_form_sheet.dart';
import 'widgets/user_form_values.dart';

/// Alta de cuenta institucional, solo del administrador (`POST /users`).
/// La cuenta nace `active` y sin OTP: entra con su correo y la contraseña
/// que se le pone aquí.
class UserFormScreen extends ConsumerStatefulWidget {
  const UserFormScreen({super.key});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _values = UserFormValues();
  Map<UserInput, String> _errors = const {};
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
      body: hubs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => MessageView(message: ApiException.messageOf(error)),
        data: _form,
      ),
    );
  }

  Widget _form(List<Hub> hubs) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.only(bottom: bottom + 24),
      children: [
        SectionHeader(
          title: 'Nueva cuenta',
          subtitle: 'Entra con su correo y esta contraseña.',
          onBack: () => context.go('/users'),
        ),
        Transform.translate(
          offset: const Offset(0, -24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RiseIn(
              child: UserFormSheet(
                values: _values,
                hubs: hubs,
                errors: _errors,
                shakeCount: _shakeCount,
                onChanged: () => setState(
                  () => _errors = {..._errors}..remove(UserInput.hubs),
                ),
                onCreateHub: () => context.go('/hubs/new'),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AuthMorphButton(
            label: 'Crear cuenta',
            loadingLabel: 'Creando la cuenta',
            isLoading: _isLoading,
            onPressed: hubs.isEmpty ? null : _submit,
          ),
        ),
      ],
    );
  }
}
