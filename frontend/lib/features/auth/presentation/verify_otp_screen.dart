import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'widgets/otp_code_input.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key, required this.contact});

  final AuthContact? contact;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  static const _ttlSeconds = 10 * 60;
  String _code = '';
  int _secondsRemaining = _ttlSeconds;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _noticeMessage;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _noticeMessage = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(VerifyOtpRequest(contact: contact, code: _code));
      if (mounted) context.go('/home');
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'No se pudo verificar el código. Intenta de nuevo.',
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
      _noticeMessage = null;
    });
    try {
      final response = await ref
          .read(authControllerProvider.notifier)
          .resendOtp(ResendOtpRequest(contact: contact));
      if (!mounted) return;
      _startCountdown();
      setState(() => _noticeMessage = response.message);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => context.go('/register'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Verifica tu cuenta',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enviamos un código de 6 dígitos a $_contactLabel.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  if (_errorMessage != null) ...[
                    ErrorBanner(
                      message: _errorMessage!,
                      onDismiss: () => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (_noticeMessage != null) ...[
                    ErrorBanner(
                      message: _noticeMessage!,
                      success: true,
                      onDismiss: () => setState(() => _noticeMessage = null),
                    ),
                    const SizedBox(height: 18),
                  ],
                  OtpCodeInput(
                    onChanged: (value) => setState(() => _code = value),
                  ),
                  const SizedBox(height: 18),
                  if (_secondsRemaining > 0)
                    Text(
                      'Reenviar código en $_countdownLabel',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    TextButton(
                      onPressed: _isResending ? null : _resend,
                      child: const Text('Solicitar nuevo código'),
                    ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Verificar',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    '¿Problemas con el código? Contacta a soporte médico.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
