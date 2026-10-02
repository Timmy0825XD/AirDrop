import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/field_limits.dart';
import 'package:frontend/core/validators.dart';

void main() {
  group('documento', () {
    test('cédula acepta de 6 a 10 dígitos', () {
      expect(Validators.documentDigits('1094923'), isNull);
      expect(Validators.documentDigits('1234567890'), isNull);
    });

    test('cédula rechaza letras, vacíos y fuera de rango', () {
      expect(
        Validators.documentDigits('ABC123'),
        Validators.invalidDocumentMessage,
      );
      expect(
        Validators.documentDigits('12345'),
        Validators.invalidDocumentMessage,
      );
      expect(
        Validators.documentDigits('12345678901'),
        Validators.invalidDocumentMessage,
      );
      expect(Validators.documentDigits(''), 'Escribe el número de documento.');
      expect(Validators.documentDigits(null), isNotNull);
    });

    test('PPT acepta de 6 a 15 caracteres y pasa a mayúsculas', () {
      expect(Validators.documentPpt('ab1234'), isNull);
      expect(Validators.documentPpt('CA12345678'), isNull);
    });

    test('PPT rechaza guiones y es espacios', () {
      expect(
        Validators.documentPpt('AB-123'),
        Validators.invalidDocumentMessage,
      );
      expect(
        Validators.documentPpt('A B C'),
        Validators.invalidDocumentMessage,
      );
    });

    test('el tope de documento sale de FieldLimits', () {
      expect(FieldLimits.documentNumber, 15);
      final largo = '1' * 16;
      expect(Validators.documentDigits(largo), contains('15'));
    });
  });

  group('lote', () {
    test('acepta letras, números y guiones de 3 a 20', () {
      expect(Validators.lotCode('ABC-12'), isNull);
      expect(Validators.lotCode('L01'), isNull);
    });

    test('pasa a mayúsculas antes de validar', () {
      expect(Validators.lotCode('abc-12'), isNull);
    });

    test('rechaza largo vacío y símbolos', () {
      expect(Validators.lotCode(''), 'Escribe el lote.');
      expect(
        Validators.lotCode('AB'),
        'El lote debe tener entre 3 y 20 letras, números o guiones.',
      );
      expect(
        Validators.lotCode('LOTE*1'),
        'El lote debe tener entre 3 y 20 letras, números o guiones.',
      );
      expect(
        Validators.lotCode('L' * 21),
        'El lote debe tener entre 3 y 20 letras, números o guiones.',
      );
    });
  });

  group('fecha AAAA-MM-DD', () {
    test('acepta el formato estricto', () {
      expect(Validators.isoDate('2027-01-31'), isNull);
    });

    test('rechaza otros formatos', () {
      expect(Validators.isoDate('31/01/2027'), contains('AAAA-MM-DD'));
      expect(Validators.isoDate('2027-1-31'), contains('AAAA-MM-DD'));
      expect(Validators.isoDate(''), 'Escribe La fecha.');
    });

    test('acepta una etiqueta para la fecha', () {
      expect(
        Validators.isoDate('x', label: 'La fecha estimada'),
        'La fecha estimada debe ser AAAA-MM-DD.',
      );
    });
  });

  group('coordenadas', () {
    test('latitud entre -90 y 90', () {
      expect(Validators.latitude('10.463140'), isNull);
      expect(Validators.latitude('-90'), isNull);
      expect(Validators.latitude('90.1'), 'La latitud no es válida.');
      expect(Validators.latitude('norte'), 'La latitud no es válida.');
      expect(Validators.latitude(''), 'Escribe la latitud.');
    });

    test('longitud entre -180 y 180', () {
      expect(Validators.longitude('-73.253220'), isNull);
      expect(Validators.longitude('180'), isNull);
      expect(Validators.longitude('180.1'), 'La longitud no es válida.');
      expect(Validators.longitude(''), 'Escribe la longitud.');
    });
  });

  group('motivo, identificador y nombres', () {
    test('motivo obligatorio y opcional', () {
      expect(Validators.reason(''), 'Escribe el motivo.');
      expect(Validators.reason('', required: false), isNull);
      expect(Validators.reason('Zona militar'), isNull);
      expect(Validators.reason('x' * 161), contains('160'));
    });

    test('identificador de dron hasta 32', () {
      expect(Validators.droneIdentifier('DRON-01'), isNull);
      expect(Validators.droneIdentifier(''), 'Escribe el identificador.');
      expect(Validators.droneIdentifier('D' * 33), contains('32'));
    });

    test('nombres con tope de 80', () {
      expect(Validators.hubName('Central de prueba'), isNull);
      expect(Validators.medicationName('Acetaminofén'), isNull);
      expect(Validators.geofenceName('Zona norte'), isNull);
      expect(Validators.hubName('C' * 81), contains('80'));
    });

    test('dirección con tope de 160', () {
      expect(Validators.address('Calle 1 #2-3'), isNull);
      expect(Validators.address(''), 'Escribe la dirección.');
      expect(Validators.address('a' * 161), contains('160'));
    });
  });

  group('los validadores existentes siguen igual', () {
    test('nombre, correo, celular, contraseña y OTP', () {
      expect(Validators.name('Ana'), isNull);
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.phone('3001234567'), isNull);
      expect(Validators.password('Demo1234'), isNull);
      expect(Validators.otp('123456'), isNull);
    });

    test('el celular con prefijo +57 se normaliza y se acepta', () {
      // El prefijo se quita antes de validar, porque Nest exige 10
      // dígitos y solo quita lo que no es dígito. Antes de la Fase 3
      // estos dos casos fallaban y llegaban 12 dígitos a la API.
      expect(Validators.phone('+57 300 123 4567'), isNull);
      expect(Validators.phone('573001234567'), isNull);
      expect(Validators.phone('+57 (300) 123-45.67'), isNull);
    });

    test('el celular que no son 10 dígitos se sigue rechazando', () {
      expect(Validators.phone('300123456'), isNotNull);
      expect(Validators.phone('30012345678'), isNotNull);
      expect(Validators.phone('abcdefghij'), isNotNull);
    });
  });
}
