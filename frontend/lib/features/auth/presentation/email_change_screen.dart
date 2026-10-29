import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/field_limits.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/message_view.dart';
import '../../home/presentation/widgets/section_form_page.dart';
import '../../home/presentation/widgets/section_header.dart';
import 'auth_controller.dart';
import 'widgets/auth_morph_button.dart';
import 'widgets/profile/email_change_card.dart';

/// Confirmar el correo nuevo (`/profile/email`, RNF-04). El correo no
/// cambia hasta que entra el código; mientras tanto se entra con el actual.
/// Reenviar se habilita a los 45 s (Nest deja 5 por minuto).
class EmailChangeScreen extends ConsumerStatefulWidget {
  const EmailChangeScreen({super.key});

  @override
  ConsumerState<EmailChangeScreen> createState() => _EmailChangeScreenState();
}

class _EmailChangeScreenState extends ConsumerState<EmailChangeScreen>
    with SingleTickerProviderStateMixin {
  static const _resendSeconds = 45;

  final _input = TextEditingController();
  late final _collapse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  Timer? _timer;
  int _secondsLeft = _resendSeconds;
  bool _busy = false;
  String? _error;
  String? _info;
  int _shakeCount = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _collapse.dispose();
    _input.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) timer.cancel();
      if (mounted) setState(() => _secondsLeft--);
    });
  }

  AuthController get _auth => ref.read(authControllerProvider.notifier);

  Future<void> _confirm() async {
    final code = _input.text.trim();
    if (code.length != FieldLimits.otpDigits) {
      setState(() {
        _error = 'Escribe los ${FieldLimits.otpDigits} dígitos del código.';
        _shakeCount++;
      });
      return;
    }
    await _run(() async {
      await _auth.confirmEmailChange(code);
      await _collapse.forward();
      if (!mounted) return;
      showAppSnack(context, 'Listo. Tu correo nuevo ya está activo.');
      SectionHeader.backOrHome(context);
    });
  }

  Future<void> _resend() => _run(() async {
    final message = await _auth.resendEmailChange();
    if (!mounted) return;
    setState(() => _info = message.message);
    _startCountdown();
  });

  Future<void> _cancel() => _run(() async {
    await _auth.cancelEmailChange();
    if (!mounted) return;
    showAppSnack(context, 'Cambio de correo cancelado.', tone: SnackTone.info);
    SectionHeader.backOrHome(context);
  });

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (!mounted) return;
      _input.clear();
      setState(() {
        _error = e.message;
        _shakeCount++;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(authControllerProvider).value?.user?.pendingEmail;
    final header = SectionHeader(
      title: 'Confirma tu correo',
      subtitle: 'Cambio de correo',
      onBack: () => SectionHeader.backOrHome(context),
    );
    if (pending == null) {
      return Scaffold(
        body: Column(
          children: [
            header,
            const Expanded(
              child: MessageView(
                icon: Icons.mark_email_read_outlined,
                message: 'No tienes un cambio de correo pendiente.',
              ),
            ),
          ],
        ),
      );
    }
    return SectionFormPage(
      header: header,
      card: EmailChangeCard(
        pendingEmail: pending,
        input: _input,
        collapse: _collapse,
        onSubmitted: _confirm,
        onResend: _busy ? null : _resend,
        onCancel: _busy ? null : _cancel,
        secondsLeft: _secondsLeft,
        error: _error,
        info: _info,
        shakeCount: _shakeCount,
        enabled: !_busy,
      ),
      button: AuthMorphButton(
        label: 'Confirmar correo',
        loadingLabel: 'Confirmando',
        isLoading: _busy,
        onPressed: _busy ? null : _confirm,
      ),
    );
  }
}
