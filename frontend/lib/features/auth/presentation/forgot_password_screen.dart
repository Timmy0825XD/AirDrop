import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'widgets/auth_brand.dart';
import 'widgets/contact_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contact = AuthContact.parse(_contactController.text);
      await ref
          .read(authControllerProvider.notifier)
          .forgotPassword(ForgotPasswordRequest(contact: contact));
      if (mounted) context.go('/reset-password', extra: contact);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _errorMessage = 'No se pudo enviar el código. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateContact(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe tu correo o celular.';
    final looksLikeEmail = RegExp(r'[A-Za-z@]').hasMatch(text);
    return looksLikeEmail ? Validators.email(text) : Validators.phone(text);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('AirDrop'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthBrandMark(),
                    const SizedBox(height: 24),
                    Text(
                      'Recuperar contraseña',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa el correo o celular vinculado a tu cuenta para recibir el código de verificación.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null) ...[
                      ErrorBanner(
                        message: _errorMessage!,
                        onDismiss: () => setState(() => _errorMessage = null),
                      ),
                      const SizedBox(height: 18),
                    ],
                    ContactField(
                      controller: _contactController,
                      validator: _validateContact,
                      onChanged: (_) {
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Enviar código',
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Regresar al inicio de sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
