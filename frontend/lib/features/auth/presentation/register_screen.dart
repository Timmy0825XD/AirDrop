import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/validators.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'widgets/auth_page.dart';
import 'widgets/login/login_form_alert.dart';
import 'widgets/login/login_glass_card.dart';
import 'widgets/register/register_fields.dart';
import 'widgets/register/register_header.dart';
import 'widgets/register/register_info_banner.dart';
import 'widgets/register/register_role_section.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.requester;
  bool _consentAccepted = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailValue();
    final phone = _phoneValue();
    if (email == null && phone == null) {
      setState(() => _errorMessage = 'Indica un correo o un celular.');
      return;
    }
    if (!_consentAccepted) {
      setState(
        () =>
            _errorMessage = 'Debes aceptar el tratamiento de datos personales.',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            RegisterRequest(
              fullName: _name.text,
              email: email,
              phone: phone,
              password: _password.text,
              role: _role,
              consentAccepted: true,
            ),
          );
      if (!mounted) return;
      final contact = email != null
          ? AuthContact.email(email)
          : AuthContact.phone(phone!);
      context.go('/verify-otp', extra: contact);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'No se pudo crear la cuenta. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    if (_emailValue() == null) {
      return _role.requiresEmail ? 'El correo es obligatorio.' : null;
    }
    return Validators.email(value);
  }

  String? _validatePhone(String? value) {
    if (_phoneValue() == null) return null;
    return Validators.phone(value);
  }

  String? _emailValue() {
    final value = _email.text.trim();
    return value.isEmpty ? null : value.toLowerCase();
  }

  String? _phoneValue() {
    final value = _phone.text.replaceAll(RegExp(r'\D'), '');
    return value.isEmpty ? null : value;
  }

  void _clearError(String _) {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return AuthPage(
      maxWidth: 520,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RegisterHeader(onBack: () => context.go('/login')),
            const SizedBox(height: 12),
            Text(
              'Únete a la red de despacho y recepción médica autónoma.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            AuthFormAlert(
              message: _errorMessage,
              onDismiss: () => setState(() => _errorMessage = null),
              bottomPadding: 16,
            ),
            LoginGlassCard(
              child: RegisterFields(
                nameController: _name,
                emailController: _email,
                phoneController: _phone,
                passwordController: _password,
                consentAccepted: _consentAccepted,
                isLoading: _isLoading,
                onSubmit: _submit,
                onConsentChanged: (value) => setState(() {
                  _consentAccepted = value;
                  _errorMessage = null;
                }),
                roleSection: RegisterRoleSection(
                  selectedRole: _role,
                  onChanged: (role) => setState(() {
                    _role = role;
                    _errorMessage = null;
                  }),
                ),
                validators: RegisterFieldValidators(
                  name: Validators.name,
                  email: _validateEmail,
                  phone: _validatePhone,
                  password: Validators.password,
                  onChanged: _clearError,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const RegisterInfoBanner(),
            const SizedBox(height: 24),
            const _LoginLinkRow(),
          ],
        ),
      ),
    );
  }
}

class _LoginLinkRow extends StatelessWidget {
  const _LoginLinkRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes cuenta?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Inicia sesión',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}