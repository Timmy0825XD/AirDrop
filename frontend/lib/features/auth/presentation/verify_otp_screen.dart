import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/field_limits.dart';
import '../../../core/widgets/app_snack.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'login_screen.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_morph_button.dart';
import 'widgets/auth_step_scaffold.dart';
import 'widgets/circle_reveal.dart';
import 'widgets/otp/otp_code_field.dart';
import 'widgets/otp/otp_verify_content.dart';

/// Verificación del código de registro (paso 2 de 2). La cuenta vive en
/// `unverified` hasta que entra el código, que dura 10 minutos en Nest
/// (`OTP_SIGNUP_TTL_MS`). Verificar abre la sesión: tras el check, el círculo
/// de marca cubre la pantalla y se entra al inicio.
class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key, required this.contact});

  final AuthContact? contact;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen>
    with TickerProviderStateMixin {
  /// Espera antes de poder pedir otro código. Es solo del lado de la app.
  static const _resendSeconds = 45;

  final _code = TextEditingController();
  final _fieldKey = GlobalKey();
  late final _collapse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  );
  late final _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );
  late final _revealCurve = CurvedAnimation(
    parent: _reveal,
    curve: Curves.easeInOutCubic,
  );

  Timer? _timer;
  int _secondsLeft = _resendSeconds;
  bool _isLoading = false;
  bool _isResending = false;
  bool _verified = false;
  int _shakeCount = 0;
  String? _errorMessage;
  Offset _revealCenter = Offset.zero;

  @override
  void initState() {
    super.initState();
    _code.addListener(_onCodeChanged);
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _revealCurve.dispose();
    _collapse.dispose();
    _reveal.dispose();
    super.dispose();
  }

  bool get _reducedMotion => MediaQuery.disableAnimationsOf(context);
  bool get _isComplete => _code.text.length == FieldLimits.otpDigits;

  void _onCodeChanged() {
    // Redibuja el botón (se enciende con 6 dígitos) y limpia el error.
    setState(() => _errorMessage = null);
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _secondsLeft <= 1) timer.cancel();
      if (mounted) setState(() => _secondsLeft--);
    });
  }

  Future<void> _verify() async {
    final contact = widget.contact;
    if (_isLoading || _verified || !_isComplete) return;
    if (contact == null) {
      setState(
        () => _errorMessage = 'No encontramos el contacto de la cuenta.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(VerifyOtpRequest(contact: contact, code: _code.text));
      if (!mounted) return;
      _timer?.cancel();
      FocusScope.of(context).unfocus();
      setState(() {
        _isLoading = false;
        _verified = true;
      });
      await _celebrate();
      if (mounted) context.go('/home');
    } on ApiException catch (error) {
      _fail(error.message);
    } catch (_) {
      _fail('No se pudo verificar el código. Intenta de nuevo.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = message;
      _shakeCount++;
    });
  }

  /// Las cajas se juntan en el check y, tras un respiro, el círculo de
  /// marca crece desde el check hasta cubrir la pantalla.
  Future<void> _celebrate() async {
    if (_reducedMotion) return;
    await _collapse.forward();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || box == null) return;
    setState(
      () => _revealCenter = box.localToGlobal(box.size.center(Offset.zero)),
    );
    await _reveal.forward();
  }

  Future<void> _resend() async {
    final contact = widget.contact;
    if (contact == null || _isResending) return;
    setState(() => _isResending = true);
    try {
      final response = await ref
          .read(authControllerProvider.notifier)
          .resendOtp(ResendOtpRequest(contact: contact));
      if (!mounted) return;
      _startCountdown();
      showAppSnack(context, response.message);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);
    return AuthStepScaffold(
      pill: 'Paso 2 de 2',
      icon: Icons.verified_user_outlined,
      onBack: () => context.go('/login', extra: LoginScreen.returnExtra),
      overlay: CircleReveal(progress: _revealCurve, center: _revealCenter),
      body: _body(),
      action: AnimatedOpacity(
        opacity: _verified ? 0 : 1,
        duration: const Duration(milliseconds: 320),
        child: Center(
          child: AuthMorphButton(
            label: 'Verificar',
            loadingLabel: 'Verificando',
            isLoading: _isLoading,
            onPressed: _isComplete && !_verified ? _verify : null,
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final contact = widget.contact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OtpHeading(
          contactLabel: contact?.email ?? contact?.phone ?? 'tu correo',
        ),
        const SizedBox(height: 28),
        OtpCodeField(
          key: _fieldKey,
          controller: _code,
          collapse: _collapse,
          hasError: _errorMessage != null,
          shakeCount: _shakeCount,
          enabled: !_verified && !_isLoading,
          onSubmitted: _verify,
        ),
        AuthFieldError(message: _errorMessage),
        const SizedBox(height: 16),
        OtpStatus(
          verified: _verified,
          secondsLeft: _secondsLeft,
          totalSeconds: _resendSeconds,
          onResend: _isResending ? null : _resend,
        ),
      ],
    );
  }
}
