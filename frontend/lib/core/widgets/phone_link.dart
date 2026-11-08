import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../colombian_phone.dart';
import 'app_snack.dart';

/// Abre el marcador del teléfono con el número. Si el dispositivo no
/// puede llamar (un computador sin app de llamadas), lo avisa.
Future<void> callPhone(BuildContext context, String phone) async {
  final uri = colombianPhoneUri(phone);
  final opened = uri != null && await launchUrl(uri);
  if (!opened && context.mounted) {
    showAppSnack(
      context,
      'No se pudo abrir el marcador. El número es '
      '${formatColombianPhone(phone)}.',
      tone: SnackTone.info,
    );
  }
}

/// Un teléfono con formato colombiano (`300 123 4567`) que se toca para
/// llamar: ícono, número en el color del acento y 48 px de alto para el
/// dedo. Si no es un número de 10 dígitos, solo se muestra.
class PhoneLink extends StatelessWidget {
  const PhoneLink({super.key, required this.phone, this.style});

  final String phone;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = formatColombianPhone(phone);
    final base = style ?? theme.textTheme.bodyMedium;
    if (colombianPhoneUri(phone) == null) return Text(text, style: base);
    final color = theme.colorScheme.primary;
    return Semantics(
      button: true,
      label: 'Llamar al $text',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => callPhone(context, phone),
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call_outlined, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                text,
                style: base?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
