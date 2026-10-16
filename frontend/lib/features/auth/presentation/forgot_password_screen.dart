import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/validators.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'login_screen.dart';
import 'widgets/auth_morph_button.dart';
import 'widgets/auth_step_scaffold.dart';
import 'widgets/auth_text_link.dart';
import 'widgets/forgot/forgot_password_content.dart';

/// Recuperación de contraseña. Llega desde el login: el encabezado alto se
/// encoge y la llave gira al entrar. Al enviar, el botón se vuelve el dron,
/// aparece la confirmación y el botón vuelve como "Ingresar el código".
///
/// El backend siempre responde el mismo mensaje
/// (`Si el contacto existe, te enviaremos un código.`), así que esta
/// pantalla no revela si la cuenta existe.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _isLoading = false;
  int _shakeCount = 0;
  String? _errorMessage;

  /// Mensaje de Nest tras enviar; mientras sea `null` no se ha enviado.
  String? _sentMessage;
  AuthContact? _contact;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_isLoading) return;
    final error = Validators.email(_email.text);
    if (error != null) {
      setState(() {
        _errorMessage = error;
        _shakeCount++;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    final contact = AuthContact.email(_email.text.trim().toLowerCase());
    try {
      final response = await ref
          .read(authControllerProvider.notifier)
          .forgotPassword(ForgotPasswordRequest(contact: contact));
      if (!mounted) return;
      setState(() {
        _contact = contact;
        _sentMessage = response.message;
      });
    } on ApiException catch (error) {
      _fail(error.message);
    } catch (_) {
      _fail('No se pudo enviar el código. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _shakeCount++;
    });
  }

  void _clearError(String _) {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  void _toLogin() => context.go('/login', extra: LoginScreen.returnExtra);

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);
    final sent = _sentMessage != null;

    return AuthStepScaffold(
      fromTall: true,
      icon: Icons.key_rounded,
      turnIcon: true,
      onBack: _toLogin,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ForgotPasswordForm(
            email: _email,
            errorText: _errorMessage,
            shakeCount: _shakeCount,
            enabled: !sent,
            onChanged: _clearError,
            onSubmitted: _send,
          ),
          ForgotSentCard(message: _sentMessage),
        ],
      ),
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AuthMorphButton(
              label: sent ? 'Ingresar el código' : 'Enviar código',
              loadingLabel: 'Enviando código',
              isLoading: _isLoading,
              onPressed: sent
                  ? () => context.go('/reset-password', extra: _contact)
                  : _send,
            ),
          ),
          const SizedBox(height: 10),
          AuthTextLink(
            question: '¿La recordaste?',
            action: 'Inicia sesión',
            onPressed: _toLogin,
          ),
        ],
      ),
    );
  }
}
