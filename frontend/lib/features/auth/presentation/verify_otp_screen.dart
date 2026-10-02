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
import 'widgets/otp/otp_verify_content.dart';

/// Verificación del código de registro. La cuenta vive en `unverified`
/// hasta que entra el código; el temporizador de 10 minutos es el TTL que
/// usa Nest (`OTP_SIGNUP_TTL_MS`).
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
    if (_code.length != FieldLimits.otpDigits) {
      setState(
        () =>
            _errorMessage =
                'Escribe los ${FieldLimits.otpDigits} dígitos del código.',
      );
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
          () => _errorMessage = 'No se pudo verificar el código. Intenta de nuevo.',
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

  void _dismissMessage() {
    setState(() {
      if (_errorMessage != null) {
        _errorMessage = null;
      } else {
        _noticeMessage = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);

    return AuthPage(
      maxWidth: 440,
      child: Column(
        children: [
          AuthTopBar(
            onBack: () => context.go('/register'),
            showTitle: true,
          ),
          const SizedBox(height: 12),
          OtpVerifyContent(
            contactLabel: _contactLabel,
            onCodeChanged: (value) => setState(() => _code = value),
            onResend: _resend,
            onSubmit: _submit,
            errorMessage: _errorMessage,
            noticeMessage: _noticeMessage,
            onDismissMessage: _dismissMessage,
            secondsRemaining: _secondsRemaining,
            countdownLabel: _countdownLabel,
            canResend: _secondsRemaining == 0 && !_isResending,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}