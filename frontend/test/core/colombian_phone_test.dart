import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/colombian_phone.dart';

void main() {
  test('celular y fijo en grupos de 3, 3 y 4', () {
    expect(formatColombianPhone('3001234567'), '300 123 4567');
    expect(formatColombianPhone('+57 300 123 4567'), '300 123 4567');
    expect(formatColombianPhone('6055700000'), '605 570 0000');
  });

  test('lo que no tiene 10 dígitos se deja como llegó', () {
    expect(formatColombianPhone(' 12345 '), '12345');
    expect(formatColombianPhone(null), '');
  });

  test('el enlace para llamar lleva el +57', () {
    expect(colombianPhoneUri('300 123 4567').toString(), 'tel:+573001234567');
    expect(colombianPhoneUri('12345'), isNull);
  });
}
