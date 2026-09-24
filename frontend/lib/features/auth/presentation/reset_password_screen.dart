import 'dart:async';

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
import 'widgets/otp_code_input.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.contact});

  final AuthContact? contact;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  static const _ttlSeconds = 15 * 60;
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _code = '';
  int _secondsRemaining = _ttlSeconds;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _successMessage;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsRemaining = _ttlSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String get _contactLabel =>
      widget.contact?.email ?? widget.contact?.phone ?? 'tu contacto';

  String get _countdownLabel {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _submit() async {
    final contact = widget.contact;
    if (contact == null) {
      setState(
        () => _errorMessage = 'No encontramos el contacto de la cuenta.',
      );
      return;
    }
    if (_code.length != 6) {
      setState(() => _errorMessage = 'Escribe los 6 dígitos del código.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ref
          .read(authControllerProvider.notifier)
          .resetPassword(
            ResetPasswordRequest(
              contact: contact,
              code: _code,
              password: _passwordController.text,
            ),
          );
      if (mounted) setState(() => _successMessage = response.message);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'No se pudo actualizar la contraseña. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    final contact = widget.contact;
    if (contact == null || _isResending) return;
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .forgotPassword(ForgotPasswordRequest(contact: contact));
      if (mounted) {
        _startCountdown();
        setState(() => _errorMessage = null);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) return 'Confirma tu nueva contraseña.';
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => context.go('/forgot-password'),
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
              child: _successMessage != null
                  ? _SuccessView(
                      message: _successMessage!,
                      onContinue: () => context.go('/login'),
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Nueva contraseña',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ingresa el código enviado a $_contactLabel y define una nueva contraseña.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          if (_errorMessage != null) ...[
                            ErrorBanner(
                              message: _errorMessage!,
                              onDismiss: () =>
                                  setState(() => _errorMessage = null),
                            ),
                            const SizedBox(height: 18),
                          ],
                          OtpCodeInput(
                            onChanged: (value) => setState(() => _code = value),
                          ),
                          const SizedBox(height: 12),
                          if (_secondsRemaining > 0)
                            Text(
                              'El código expira en $_countdownLabel',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            )
                          else
                            TextButton(
                              onPressed: _isResending ? null : _resend,
                              child: const Text('Reenviar código'),
                            ),
                          const SizedBox(height: 18),
                          AppTextField(
                            label: 'Nueva contraseña',
                            controller: _passwordController,
                            obscureText: true,
                            keyboardType: TextInputType.visiblePassword,
                            maxLength: FieldLimits.passwordMax,
                            textInputAction: TextInputAction.next,
                            validator: Validators.password,
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            label: 'Confirmar contraseña',
                            controller: _confirmPasswordController,
                            obscureText: true,
                            keyboardType: TextInputType.visiblePassword,
                            maxLength: FieldLimits.passwordMax,
                            textInputAction: TextInputAction.done,
                            validator: _validateConfirmation,
                          ),
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: 'Actualizar contraseña',
                            isLoading: _isLoading,
                            onPressed: _submit,
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

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.message, required this.onContinue});

  final String message;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 64,
          color: theme.colorScheme.tertiary,
        ),
        const SizedBox(height: 18),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Ir al inicio de sesión', onPressed: onContinue),
      ],
    );
  }
}
