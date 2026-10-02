import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/colombian_phone.dart';
import '../../../core/validators.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'widgets/auth_page.dart';
import 'widgets/document_type_labels.dart';
import 'widgets/login/login_form_alert.dart';
import 'widgets/login/login_glass_card.dart';
import 'widgets/register/register_document_section.dart';
import 'widgets/register/register_fields.dart';
import 'widgets/register/register_header.dart';
import 'widgets/register/register_info_banner.dart';

/// Alta pública del solicitante. No hay campo de rol: el despachador y el
/// operador los crea el administrador.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _documentNumber = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  DocumentType _documentType = DocumentType.citizenshipId;
  bool _consentAccepted = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _name.dispose();
    _documentNumber.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_consentAccepted) {
      setState(
        () =>
            _errorMessage = 'Debes aceptar el tratamiento de datos personales.',
      );
      return;
    }

    final phone = normalizeColombianPhone(_phone.text);
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
              fullName: _name.text,
              documentType: _documentType,
              documentNumber: _documentNumber.text,
              phone: phone,
              password: _password.text,
              consentAccepted: true,
              email: _emailValue(),
            ),
          );
      if (!mounted) return;
      // El código de un uso va al celular, que es el único contacto
      // obligatorio del registro.
      context.go('/verify-otp', extra: AuthContact.phone(phone));
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

  /// La cédula es solo dígitos y el PPT admite letras: el patrón depende
  /// del tipo elegido, igual que en Nest.
  String? _validateDocument(String? value) =>
      DocumentTypeLabels.usesDigits(_documentType)
      ? Validators.documentDigits(value)
      : Validators.documentPpt(value);

  String? _validateEmail(String? value) {
    if (_emailValue() == null) return null;
    return Validators.email(value);
  }

  String? _emailValue() {
    final value = _email.text.trim();
    return value.isEmpty ? null : value.toLowerCase();
  }

  void _clearError(String _) {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return AuthPage(
      maxWidth: 520,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RegisterHeader(onBack: () => context.go('/login')),
            const SizedBox(height: 12),
            Text(
              'Únete a la red de despacho y recepción médica autónoma.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            AuthFormAlert(
              message: _errorMessage,
              onDismiss: () => setState(() => _errorMessage = null),
              bottomPadding: 16,
            ),
            LoginGlassCard(
              child: RegisterFields(
                nameController: _name,
                documentNumberController: _documentNumber,
                phoneController: _phone,
                emailController: _email,
                passwordController: _password,
                consentAccepted: _consentAccepted,
                isLoading: _isLoading,
                onSubmit: _submit,
                onConsentChanged: (value) => setState(() {
                  _consentAccepted = value;
                  _errorMessage = null;
                }),
                documentSection: RegisterDocumentSection(
                  type: _documentType,
                  onTypeChanged: (type) => setState(() {
                    _documentType = type;
                    _errorMessage = null;
                  }),
                  numberController: _documentNumber,
                  validator: _validateDocument,
                  onChanged: _clearError,
                ),
                validators: RegisterFieldValidators(
                  name: Validators.name,
                  documentNumber: _validateDocument,
                  phone: Validators.phone,
                  email: _validateEmail,
                  password: Validators.password,
                  onChanged: _clearError,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const RegisterInfoBanner(),
            const SizedBox(height: 24),
            const _LoginLinkRow(),
          ],
        ),
      ),
    );
  }
}

class _LoginLinkRow extends StatelessWidget {
  const _LoginLinkRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes cuenta?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Inicia sesión',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}
