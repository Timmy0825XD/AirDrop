import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/field_limits.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'widgets/role_selector.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.requester;
  bool _consentAccepted = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
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
              fullName: _nameController.text,
              email: email,
              phone: phone,
              password: _passwordController.text,
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
    final value = _emailController.text.trim();
    return value.isEmpty ? null : value.toLowerCase();
  }

  String? _phoneValue() {
    final value = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return value.isEmpty ? null : value;
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _role = role;
      _errorMessage = null;
    });
  }

  void _clearError(String _) {
    if (_errorMessage != null) setState(() => _errorMessage = null);
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
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Crear cuenta', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(
                      'Únete a la red de despacho y recepción médica autónoma.',
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
                    AppTextField(
                      label: 'Nombre completo',
                      controller: _nameController,
                      maxLength: FieldLimits.fullName,
                      textInputAction: TextInputAction.next,
                      validator: Validators.name,
                      onChanged: _clearError,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Rol operativo aeromédico',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    RoleSelector(
                      selectedRole: _role,
                      onChanged: _onRoleChanged,
                    ),
                    if (_role.requiresEmail) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Correo institucional obligatorio.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'Correo electrónico',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      maxLength: FieldLimits.email,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      onChanged: _clearError,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Celular de contacto',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: _validatePhone,
                      onChanged: _clearError,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Contraseña de acceso',
                      controller: _passwordController,
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      maxLength: FieldLimits.passwordMax,
                      textInputAction: TextInputAction.done,
                      validator: Validators.password,
                      onChanged: _clearError,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _consentAccepted,
                      onChanged: (value) => setState(() {
                        _consentAccepted = value ?? false;
                        _errorMessage = null;
                      }),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Acepto el tratamiento de datos personales y la política de privacidad.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Crear cuenta',
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Ya tienes cuenta?',
                          style: theme.textTheme.bodySmall,
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Inicia sesión'),
                        ),
                      ],
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
