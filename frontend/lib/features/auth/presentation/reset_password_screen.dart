import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/field_limits.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'widgets/auth_page.dart';
import 'widgets/auth_top_bar.dart';
import 'widgets/reset/reset_code_section.dart';
import 'widgets/reset/reset_password_form.dart';
import 'widgets/reset/reset_success_view.dart';

/// Restablecimiento de contraseña. El código viaja por el mismo flujo de
/// OTP que el registro, con TTL de 15 minutos (`OTP_RESET_TTL_MS`).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.contact});

  final AuthContact? contact;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  static const _ttlSeconds = 15 * 60;
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
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
    _password.dispose();
    _confirmPassword.dispose();
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
      setState(() => _errorMessage = 'No encontramos el contacto de la cuenta.');
      return;
    }
    if (_code.length != FieldLimits.otpDigits) {
      setState(
        () =>
            _errorMessage =
                'Escribe los ${FieldLimits.otpDigits} dígitos del código.',
      );
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
              password: _password.text,
            ),
          );
      if (mounted) setState(() => _successMessage = response.message);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'No se pudo actualizar la contraseña.',
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
      if (mounted) _startCountdown();
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) return 'Confirma tu nueva contraseña.';
    if (value != _password.text) return 'Las contraseñas no coinciden.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);
    final success = _successMessage;

    return AuthPage(
      maxWidth: 440,
      child: Column(
        children: [
          AuthTopBar(onBack: () => context.go('/forgot-password')),
          const SizedBox(height: 12),
          if (success != null)
            ResetSuccessView(
              message: success,
              onContinue: () => context.go('/login'),
            )
          else
            Form(
              key: _formKey,
              child: ResetPasswordForm(
                contactLabel: _contactLabel,
                passwordController: _password,
                confirmPasswordController: _confirmPassword,
                errorMessage: _errorMessage,
                onDismissError: () => setState(() => _errorMessage = null),
                onSubmit: _submit,
                confirmValidator: _validateConfirmation,
                isLoading: _isLoading,
                codeSection: ResetCodeSection(
                  secondsRemaining: _secondsRemaining,
                  countdownLabel: _countdownLabel,
                  onCodeChanged: (value) => setState(() => _code = value),
                  onResend: _secondsRemaining == 0 && !_isResending
                      ? _resend
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}