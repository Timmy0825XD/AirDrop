import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/colombian_phone.dart';
import '../../../core/validators.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'login_screen.dart';
import 'widgets/auth_brand.dart';
import 'widgets/auth_form_sheet.dart';
import 'widgets/auth_morph_button.dart';
import 'widgets/auth_text_link.dart';
import 'widgets/document_type_labels.dart';
import 'widgets/login/login_form_alert.dart';
import 'widgets/register/register_consent_row.dart';
import 'widgets/register/register_document_section.dart';
import 'widgets/register/register_fields.dart';
import 'widgets/register/register_flight_plan.dart';
import 'widgets/register/register_header.dart';

/// Alta pública del solicitante. No hay campo de rol: el despachador y el
/// operador los crea el administrador.
///
/// Llega desde el login: el encabezado se encoge y el formulario entra de
/// lado. Al volver al login pasa lo contrario, sin repetir el splash.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _controllers = RegisterControllers();
  late final _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  );
  late final _header = CurvedAnimation(
    parent: _entry,
    curve: Curves.fastOutSlowIn,
  );
  late final _panel = CurvedAnimation(
    parent: _entry,
    curve: const Interval(0.25, 1, curve: Curves.fastOutSlowIn),
  );

  bool _started = false;
  DocumentType _documentType = DocumentType.citizenshipId;
  bool _consentAccepted = false;
  bool _isLoading = false;
  int _shakeCount = 0;
  Map<RegisterInput, String> _errors = const {};
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    MediaQuery.disableAnimationsOf(context)
        ? _entry.value = 1
        : _entry.forward();
  }

  @override
  void dispose() {
    _header.dispose();
    _panel.dispose();
    _entry.dispose();
    _controllers.dispose();
    super.dispose();
  }

  /// Valida todo de una vez y devuelve solo los campos con error.
  Map<RegisterInput, String> _validate() {
    final c = _controllers;
    // La cédula es solo dígitos y el PPT admite letras, igual que en Nest.
    final document = DocumentTypeLabels.usesDigits(_documentType)
        ? Validators.documentDigits(c.document.text)
        : Validators.documentPpt(c.document.text);
    final results = {
      RegisterInput.name: Validators.name(c.name.text),
      RegisterInput.document: document,
      RegisterInput.phone: Validators.phone(c.phone.text),
      RegisterInput.email: Validators.email(c.email.text),
      RegisterInput.password: Validators.password(c.password.text),
    };
    return {for (final MapEntry(:key, :value) in results.entries) key: ?value};
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final errors = _validate();
    if (errors.isNotEmpty) {
      setState(() {
        _errors = errors;
        _shakeCount++;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final c = _controllers;
    final email = c.email.text.trim().toLowerCase();
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            RegisterRequest(
              fullName: c.name.text,
              documentType: _documentType,
              documentNumber: c.document.text,
              phone: normalizeColombianPhone(c.phone.text),
              password: c.password.text,
              consentAccepted: true,
              email: email,
            ),
          );
      if (mounted) context.go('/verify-otp', extra: AuthContact.email(email));
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

  /// Cuántos grupos del plan de vuelo ya están bien: identidad, contacto
  /// y acceso (con el consentimiento). Solo pinta el avance.
  int _completedGroups() {
    final errors = _validate();
    bool ok(List<RegisterInput> inputs) =>
        inputs.every((input) => !errors.containsKey(input));
    return [
      ok([RegisterInput.name, RegisterInput.document]),
      ok([RegisterInput.phone, RegisterInput.email]),
      ok([RegisterInput.password]) && _consentAccepted,
    ].where((done) => done).length;
  }

  void _clearErrors(String _) {
    if (_errors.isEmpty && _errorMessage == null) return;
    setState(() {
      _errors = const {};
      _errorMessage = null;
    });
  }

  void _backToLogin() => context.go('/login', extra: LoginScreen.returnExtra);

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);
    final inset = MediaQuery.paddingOf(context).top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToLogin();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: RegisterHeaderLayer(entry: _header)),
            Positioned.fill(
              child: AuthFormSheet(
                entrance: _panel,
                from: const Offset(56, 0),
                top:
                    AuthHeaderMetrics.compact(inset) -
                    AuthHeaderMetrics.overlap,
                child: _form(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    final data = RegisterFormData(
      controllers: _controllers,
      errors: _errors,
      shakeCount: _shakeCount,
      onChanged: _clearErrors,
    );
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RegisterHeading(),
          const SizedBox(height: 18),
          ListenableBuilder(
            listenable: Listenable.merge(_controllers.all),
            builder: (context, _) =>
                RegisterFlightPlan(completed: _completedGroups()),
          ),
          const SizedBox(height: 22),
          AuthFormAlert(
            message: _errorMessage,
            onDismiss: () => setState(() => _errorMessage = null),
            bottomPadding: 16,
          ),
          RegisterIdentityFields(
            data: data,
            documentType: _documentType,
            onDocumentTypeChanged: (type) => setState(() {
              _documentType = type;
              _errors = const {};
            }),
          ),
          const SizedBox(height: 18),
          RegisterContactFields(data: data),
          const SizedBox(height: 20),
          RegisterConsentRow(
            value: _consentAccepted,
            onChanged: (value) => setState(() => _consentAccepted = value),
          ),
          const SizedBox(height: 22),
          Center(
            child: AuthMorphButton(
              pill: true,
              label: 'Crear cuenta',
              loadingLabel: 'Creando cuenta',
              isLoading: _isLoading,
              onPressed: _consentAccepted ? _submit : null,
            ),
          ),
          const SizedBox(height: 10),
          AuthTextLink(
            question: '¿Ya tienes cuenta?',
            action: 'Inicia sesión',
            onPressed: _backToLogin,
          ),
        ],
      ),
    );
  }
}
