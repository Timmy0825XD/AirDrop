/// Deja el celular en los 10 dígitos que espera Nest, para que el cliente
/// y la API hablen el mismo formato.
///
/// Nest solo quita lo que no es dígito (`value.replace(/\D/g, '')`) y
/// después exige `^\d{10}$`. Como no quita el prefijo de país, un
/// `+57 300 123 4567` llega como `573001234567` y el registro, el login y
/// la recuperación responden 400. Acá se quita ese prefijo.
///
/// Los móviles colombianos siempre tienen 10 dígitos y empiezan por 3, así
/// que 12 dígitos que arrancan en `57` no son ambiguos.
String normalizeColombianPhone(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('57')) {
    return digits.substring(2);
  }
  return digits;
}

/// El número como se lee en Colombia: celular `300 123 4567`, fijo
/// `605 570 0000` (los dos tienen 10 dígitos en grupos de 3, 3 y 4). Lo que
/// no tenga 10 dígitos se deja como llegó.
String formatColombianPhone(String? value) {
  final digits = normalizeColombianPhone(value);
  if (digits.length != 10) return (value ?? '').trim();
  return '${digits.substring(0, 3)} ${digits.substring(3, 6)} '
      '${digits.substring(6)}';
}

/// El enlace para llamar: `tel:+573001234567`. `null` si no es un número
/// colombiano de 10 dígitos.
Uri? colombianPhoneUri(String? value) {
  final digits = normalizeColombianPhone(value);
  if (digits.length != 10) return null;
  return Uri(scheme: 'tel', path: '+57$digits');
}
