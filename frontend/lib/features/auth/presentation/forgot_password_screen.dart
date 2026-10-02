import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/validators.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'widgets/auth_page.dart';
import 'widgets/forgot/forgot_method_chips.dart';
import 'widgets/forgot/forgot_password_content.dart';
import 'widgets/login/login_form_alert.dart';

/// Recuperación de contraseña. El backend siempre responde el mismo
/// mensaje (`Si el contacto existe, te enviaremos un código.`), así que
/// esta pantalla no revela si la cuenta existe.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contact = TextEditingController();
  ForgotMethod _method = ForgotMethod.email;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _contact.dispose();
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
      final contact = AuthContact.parse(_contact.text);
      await ref
          .read(authControllerProvider.notifier)
          .forgotPassword(ForgotPasswordRequest(contact: contact));
      if (mounted) context.go('/reset-password', extra: contact);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'No se pudo enviar el código. Intenta de nuevo.',
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

  void _clearError(String _) {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);

    return AuthPage(
      maxWidth: 440,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ForgotPasswordContent(
              onBack: () => context.go('/login'),
              onReturnToLogin: () => context.go('/login'),
              contactController: _contact,
              hint: _method == ForgotMethod.email
                  ? 'ej. v.morales@clinica.org'
                  : 'ej. 3001234567 o +57 300 123 4567',
              keyboardType: _method == ForgotMethod.email
                  ? TextInputType.emailAddress
                  : TextInputType.phone,
              validator: _validateContact,
              onChanged: _clearError,
              isLoading: _isLoading,
              onSubmit: _submit,
              methodChips: ForgotMethodChips(
                selected: _method,
                onChanged: (method) => setState(() => _method = method),
              ),
            ),
            AuthFormAlert(
              message: _errorMessage,
              onDismiss: () => setState(() => _errorMessage = null),
              topPadding: 16,
            ),
          ],
        ),
      ),
    );
  }
}