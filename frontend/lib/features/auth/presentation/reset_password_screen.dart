import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/field_limits.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/app_snack.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'login_screen.dart';
import 'widgets/auth_morph_button.dart';
import 'widgets/auth_step_scaffold.dart';
import 'widgets/airspace/airspace_reveal.dart';
import 'widgets/reset/reset_code_section.dart';
import 'widgets/reset/reset_password_form.dart';
import 'widgets/reset/reset_success_view.dart';

/// Los campos de la nueva contraseña, para nombrar sus errores.
enum ResetInput { code, password, confirm }

/// Nueva contraseña con el código del correo. El código dura 15 minutos
/// en Nest (`OTP_RESET_TTL_MS`). Al actualizar, desde el botón se abre el
/// espacio aéreo y aparece "Contraseña actualizada"; la sesión no se abre, se vuelve al
/// login.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.contact});

  final AuthContact? contact;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  /// Espera antes de pedir otro código; es solo de la app.
  static const _resendSeconds = 45;

  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _buttonKey = GlobalKey();
  late final _reveal = AnimationController(
    vsync: this,
    duration: AirspaceReveal.duration,
  );

  Timer? _timer;
  int _secondsLeft = _resendSeconds;
  bool _isLoading = false;
  bool _isResending = false;
  bool _showPassword = false;
  int _shakeCount = 0;
  Map<ResetInput, String> _errors = const {};
  Offset _revealCenter = Offset.zero;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _code.addListener(_clearCodeError);
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reveal.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _secondsLeft <= 1) timer.cancel();
      if (mounted) setState(() => _secondsLeft--);
    });
  }

  void _clearCodeError() {
    if (_errors.containsKey(ResetInput.code)) {
      setState(() => _errors = Map.of(_errors)..remove(ResetInput.code));
    }
  }

  /// Se redibuja al escribir: el check de coincidencia y el aviso en vivo.
  void _onPasswordChanged(String _) => setState(() {
    _errors = Map.of(_errors)
      ..remove(ResetInput.password)
      ..remove(ResetInput.confirm);
  });

  Map<ResetInput, String> _validate() {
    final confirm = _confirm.text;
    final results = {
      ResetInput.code: _code.text.length == FieldLimits.otpDigits
          ? null
          : 'Escribe los ${FieldLimits.otpDigits} dígitos del código.',
      ResetInput.password: Validators.password(_password.text),
      ResetInput.confirm: confirm.isEmpty
          ? 'Confirma tu nueva contraseña.'
          : (confirm != _password.text
                ? 'Las contraseñas no coinciden.'
                : null),
    };
    return {for (final MapEntry(:key, :value) in results.entries) key: ?value};
  }

  /// Sin esperar a enviar: si la confirmación ya es tan larga como la
  /// contraseña y no coincide, se avisa.
  String? get _liveMismatch {
    final confirm = _confirm.text;
    final mismatch =
        confirm.isNotEmpty &&
        confirm.length >= _password.text.length &&
        confirm != _password.text;
    return mismatch ? 'Las contraseñas no coinciden.' : null;
  }

  Future<void> _submit() async {
    final contact = widget.contact;
    if (_isLoading) return;
    final errors = _validate();
    if (contact == null || errors.isNotEmpty) {
      setState(() {
        _errors = contact == null
            ? {ResetInput.code: 'No encontramos el correo de la cuenta.'}
            : errors;
        _shakeCount++;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final response = await ref
          .read(authControllerProvider.notifier)
          .resetPassword(
            ResetPasswordRequest(
              contact: contact,
              code: _code.text,
              password: _password.text,
            ),
          );
      await _playReveal();
      if (mounted) setState(() => _successMessage = response.message);
    } on ApiException catch (error) {
      _fail(error.message);
    } catch (_) {
      _fail('No se pudo actualizar la contraseña.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// El código es lo que Nest suele rechazar, así que el error va ahí.
  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _errors = {ResetInput.code: message};
      _shakeCount++;
    });
  }

  Future<void> _playReveal() async {
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      setState(
        () => _revealCenter = box.localToGlobal(box.size.center(Offset.zero)),
      );
    }
    await _reveal.forward();
  }

  Future<void> _resend() async {
    final contact = widget.contact;
    if (contact == null || _isResending) return;
    setState(() => _isResending = true);
    try {
      final response = await ref
          .read(authControllerProvider.notifier)
          .forgotPassword(ForgotPasswordRequest(contact: contact));
      if (!mounted) return;
      _startCountdown();
      showAppSnack(context, response.message, tone: SnackTone.info);
    } on ApiException catch (error) {
      _fail(error.message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _toLogin() => context.go('/login', extra: LoginScreen.returnExtra);

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);
    final success = _successMessage;
    if (success != null) {
      return ResetSuccessView(message: success, onContinue: _toLogin);
    }

    return AuthStepScaffold(
      fromStep: true,
      pill: 'Recuperar acceso',
      icon: Icons.lock_reset_rounded,
      onBack: () => context.go('/forgot-password'),
      overlay: AirspaceReveal(
        progress: _reveal,
        center: _revealCenter,
        dive: false,
      ),
      body: _body(),
      action: Center(
        child: AuthMorphButton(
          pill: true,
          key: _buttonKey,
          label: 'Actualizar contraseña',
          loadingLabel: 'Actualizando contraseña',
          isLoading: _isLoading,
          onPressed: _submit,
        ),
      ),
    );
  }

  Widget _body() {
    final contact = widget.contact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResetHeading(contactLabel: contact?.email ?? 'tu correo'),
        const SizedBox(height: 22),
        ResetCodeSection(
          controller: _code,
          errorText: _errors[ResetInput.code],
          shakeCount: _shakeCount,
          secondsLeft: _secondsLeft,
          onResend: _isResending ? null : _resend,
        ),
        const SizedBox(height: 18),
        ResetPasswordFields(
          password: _password,
          confirm: _confirm,
          errors: (
            _errors[ResetInput.password],
            _errors[ResetInput.confirm] ?? _liveMismatch,
          ),
          shakeCount: _shakeCount,
          showPassword: _showPassword,
          onTogglePassword: () =>
              setState(() => _showPassword = !_showPassword),
          onChanged: _onPasswordChanged,
          onSubmit: _submit,
        ),
      ],
    );
  }
}
