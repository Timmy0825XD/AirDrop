import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/message_view.dart';
import '../../auth/presentation/widgets/auth_morph_button.dart';
import '../../home/presentation/widgets/section_form_page.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../../hubs/data/hub_models.dart';
import '../../hubs/data/hub_providers.dart';
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
  void initState() {
    super.initState();
    // Las centrales se vuelven a pedir al abrir: una creada desde otra
    // sesión no salía hasta reiniciar la app. Mientras llegan se ven las
    // que ya había.
    Future.microtask(() => ref.invalidate(allHubsProvider));
  }

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
    final header = SectionHeader(
      title: 'Nueva cuenta',
      subtitle: 'Entra con su correo y esta contraseña.',
      onBack: () => context.go('/users'),
    );
    return switch (ref.watch(assignableHubsProvider)) {
      AsyncValue(hasValue: true, hasError: false, :final value?) => _form(header, value),
      AsyncError(:final error) => SectionStatePage(
        header: header,
        body: MessageView(message: ApiException.messageOf(error)),
      ),
      _ => SectionStatePage(
        header: header,
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }

  Widget _form(Widget header, List<Hub> hubs) {
    return SectionFormPage(
      header: header,
      card: UserFormSheet(
        values: _values,
        hubs: hubs,
        errors: _errors,
        shakeCount: _shakeCount,
        onChanged: () =>
            setState(() => _errors = {..._errors}..remove(UserInput.hubs)),
        onCreateHub: () => context.go('/hubs/new'),
      ),
      button: AuthMorphButton(
        label: 'Crear cuenta',
        loadingLabel: 'Creando la cuenta',
        isLoading: _isLoading,
        onPressed: hubs.isEmpty ? null : _submit,
      ),
    );
  }
}
