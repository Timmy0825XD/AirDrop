import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/validators.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'widgets/auth_page.dart';
import 'widgets/login/login_backdrop.dart';
import 'widgets/login/login_brand_header.dart';
import 'widgets/login/login_credentials.dart';
import 'widgets/login/login_form_alert.dart';
import 'widgets/login/login_glass_card.dart';
import 'widgets/login/login_palette.dart';

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
      background: const LoginBackdrop(),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Form(key: _formKey, child: _content()),
    );
  }

  Widget _content() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LoginBrandHeader(),
        const SizedBox(height: 32),
        LoginGlassCard(child: _cardBody()),
        const SizedBox(height: 16),
        const _RegisterLinkRow(),
      ],
    );
  }

  Widget _cardBody() {
    final theme = Theme.of(context);
    final p = LoginPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Iniciar sesión',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Entra con tu correo o celular.',
          style: theme.textTheme.bodyMedium?.copyWith(color: p.muted, height: 1.5),
        ),
        const SizedBox(height: 16),
        AuthFormAlert(
          message: _errorMessage,
          onDismiss: () => setState(() => _errorMessage = null),
          bottomPadding: 16,
        ),
        LoginCredentials(
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
      ],
    );
  }
}

class _RegisterLinkRow extends StatelessWidget {
  const _RegisterLinkRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = LoginPalette.of(context);

    // Wrap y no Row: en pantallas angostas la línea se parte en dos en vez
    // de desbordar 3 px por el borde.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta?',
          style: theme.textTheme.bodyMedium?.copyWith(color: p.muted),
        ),
        TextButton(
          onPressed: () => context.go('/register'),
          style: TextButton.styleFrom(
            foregroundColor: p.accent,
            minimumSize: const Size(44, 44),
          ),
          child: Text(
            'Regístrate',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: p.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}