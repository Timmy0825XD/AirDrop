import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/validators.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'widgets/auth_brand.dart';
import 'widgets/auth_form_sheet.dart';
import 'widgets/airspace/airspace_reveal.dart';
import 'widgets/login/login_form.dart';
import 'widgets/login/login_form_alert.dart';
import 'widgets/login/login_intro.dart';
import 'widgets/login/login_timeline.dart';

/// Inicio de sesión. Al abrir la app o al cerrar sesión corre la entrada y se
/// transforma en el formulario; al volver del registro solo crece el
/// encabezado. Al entrar bien, el botón se vuelve un círculo verde con el
/// check y desde ahí la cámara se lanza al mapa antes de ir al inicio.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.returning = false});

  /// Valor de `extra` en `/login` al volver desde otra pantalla de auth
  /// (registro, código): el encabezado crece y no se repite el splash.
  static const String returnExtra = 'return';

  final bool returning;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _buttonKey = GlobalKey();

  late final _intro = AnimationController(
    vsync: this,
    duration: LoginTimeline.total,
  );
  late final _reveal = AnimationController(
    vsync: this,
    duration: AirspaceReveal.duration,
  );
  late final _back = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  );
  late final _timeline = LoginTimeline(_intro);
  late final _backHeader = CurvedAnimation(
    parent: _back,
    curve: Curves.fastOutSlowIn,
  );
  late final _backPanel = CurvedAnimation(
    parent: _back,
    curve: const Interval(0.2, 1, curve: Curves.fastOutSlowIn),
  );

  bool _started = false;
  bool _isLoading = false;
  bool _isDone = false;
  bool _showPassword = false;
  int _shakeCount = 0;
  (String?, String?) _fieldErrors = (null, null);
  String? _errorMessage;
  Offset _revealCenter = Offset.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.returning) {
      _intro.value = 1;
      _reducedMotion ? _back.value = 1 : _back.forward();
    } else {
      _reducedMotion ? _intro.value = 1 : _intro.forward();
    }
  }

  @override
  void dispose() {
    _backHeader.dispose();
    _backPanel.dispose();
    _back.dispose();
    _intro.dispose();
    _reveal.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// "Reducir movimiento" del sistema: sin entrada, sin drones, sin salida.
  bool get _reducedMotion => MediaQuery.disableAnimationsOf(context);

  /// Tocar durante la entrada salta directo a la transición al formulario.
  void _skipIntro() {
    if (_intro.value < LoginTimeline.morphStart) {
      _intro.forward(from: LoginTimeline.morphStart);
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final errors = (
      Validators.email(_email.text),
      Validators.password(_password.text),
    );
    if (errors.$1 != null || errors.$2 != null) {
      setState(() {
        _fieldErrors = errors;
        _shakeCount++;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final email = _email.text.trim().toLowerCase();
    final auth = ref.read(authControllerProvider.notifier);
    try {
      // El círculo con el dron se ve al menos un instante aunque la API
      // responda de inmediato.
      final minimum = Future<void>.delayed(const Duration(milliseconds: 700));
      final session = await auth.login(
        LoginRequest(
          contact: AuthContact.email(email),
          password: _password.text,
        ),
        announce: false,
      );
      await minimum;
      await _celebrate();
      await _playReveal();
      // Publicar la sesión hace que el router lleve al inicio; antes de la
      // salida la pantalla se habría cerrado a mitad de la animación.
      auth.announce(session);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.code == 'account_unverified') {
        context.go('/verify-otp', extra: AuthContact.email(email));
        return;
      }
      setState(() => _errorMessage = error.message);
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

  /// El botón se pone verde y dibuja el check antes de salir.
  Future<void> _celebrate() async {
    if (!mounted || _reducedMotion) return;
    setState(() => _isDone = true);
    await Future<void>.delayed(const Duration(milliseconds: 380));
  }

  /// Desde el botón se abre el espacio aéreo y la cámara se lanza al mapa.
  Future<void> _playReveal() async {
    if (!mounted || _reducedMotion) return;
    final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      setState(
        () => _revealCenter = box.localToGlobal(box.size.center(Offset.zero)),
      );
    }
    await _reveal.forward();
  }

  void _clearErrors(String _) {
    if (_fieldErrors == (null, null) && _errorMessage == null) return;
    setState(() {
      _fieldErrors = (null, null);
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);
    final returning = widget.returning;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _skipIntro,
              child: LoginIntro(
                timeline: _timeline,
                returning: returning ? _backHeader : null,
              ),
            ),
          ),
          Positioned.fill(
            child: AuthFormSheet(
              entrance: returning ? _backPanel : _timeline.form,
              from: returning ? const Offset(-56, 0) : const Offset(0, 72),
              top:
                  AuthHeaderMetrics.tallOf(context) - AuthHeaderMetrics.overlap,
              child: _form(),
            ),
          ),
          Positioned.fill(
            child: AirspaceReveal(progress: _reveal, center: _revealCenter),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LoginHeading(),
          const SizedBox(height: 20),
          AuthFormAlert(
            message: _errorMessage,
            onDismiss: () => setState(() => _errorMessage = null),
            bottomPadding: 16,
          ),
          LoginFields(
            email: _email,
            password: _password,
            errors: _fieldErrors,
            shakeCount: _shakeCount,
            showPassword: _showPassword,
            onTogglePassword: () =>
                setState(() => _showPassword = !_showPassword),
            onChanged: _clearErrors,
            onSubmit: _submit,
          ),
          LoginActions(
            buttonKey: _buttonKey,
            isLoading: _isLoading,
            isDone: _isDone,
            onSubmit: _submit,
            onForgotPassword: () => context.go('/forgot-password'),
            onRegister: () => context.go('/register'),
          ),
        ],
      ),
    );
  }
}
