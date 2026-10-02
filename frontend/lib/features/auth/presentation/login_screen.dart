import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/validators.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'widgets/auth_page.dart';
import 'widgets/login/login_brand_header.dart';
import 'widgets/login/login_credentials.dart';
import 'widgets/login/login_form_alert.dart';
import 'widgets/login/login_glass_card.dart';
import 'widgets/login/login_security_footer.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contact = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _contact.dispose();
    _password.dispose();
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
      await ref
          .read(authControllerProvider.notifier)
          .login(
            LoginRequest(
              contact: AuthContact.parse(_contact.text),
              password: _password.text,
            ),
          );
      if (mounted) context.go('/home');
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'No se pudo iniciar sesión. Intenta de nuevo.',
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LoginBrandHeader(),
            AuthFormAlert(
              message: _errorMessage,
              onDismiss: () => setState(() => _errorMessage = null),
              topPadding: 16,
            ),
            const SizedBox(height: 20),
            LoginGlassCard(
              child: LoginCredentials(
                contactController: _contact,
                passwordController: _password,
                isLoading: _isLoading,
                onSubmit: _submit,
                onForgotPassword: () => context.go('/forgot-password'),
                validators: LoginFieldValidators(
                  contact: _validateContact,
                  password: Validators.password,
                  onChanged: _clearError,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _RegisterLinkRow(),
            const SizedBox(height: 28),
            const LoginSecurityFooter(),
          ],
        ),
      ),
    );
  }
}

class _RegisterLinkRow extends StatelessWidget {
  const _RegisterLinkRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        TextButton(
          onPressed: () => context.go('/register'),
          child: Text(
            'Regístrate',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}