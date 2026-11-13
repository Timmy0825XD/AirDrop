import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orders/data/prescription_attachment.dart';
import 'package:frontend/features/orders/presentation/widgets/requester_order/prescription_picker.dart';

PrescriptionAttachment _file(String name, {int bytes = 3}) =>
    PrescriptionAttachment.fromFile(bytes: Uint8List(bytes), name: name);

Matcher _says(String message) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', message),
);

void main() {
  group('PrescriptionAttachment.fromFile', () {
    test('saca el tipo de la extensión, sin importar mayúsculas', () {
      expect(_file('hoja.JPEG').mime, 'image/jpeg');
      expect(_file('hoja.png').mime, 'image/png');
      expect(_file('EPS.pdf').isPdf, isTrue);
    });

    test('no acepta otros tipos ni más de 5 MB', () {
      expect(
        () => _file('hoja.gif'),
        _says('La fórmula debe ser un PDF o una foto JPG o PNG.'),
      );
      expect(
        () => _file('hoja.jpg', bytes: prescriptionMaxBytes + 1),
        _says('Cada archivo de la fórmula debe pesar hasta 5 MB.'),
      );
      expect(_file('hoja.jpg', bytes: prescriptionMaxBytes).name, 'hoja.jpg');
    });
  });

  group('addPrescriptionFiles (RU-25)', () {
    test('suma fotos hasta 3', () {
      final two = addPrescriptionFiles([], [_file('1.jpg'), _file('2.jpg')]);
      expect(two, hasLength(2));
      expect(addPrescriptionFiles(two, [_file('3.png')]), hasLength(3));
      expect(
        () => addPrescriptionFiles(two, [_file('3.jpg'), _file('4.jpg')]),
        _says('La fórmula va en máximo 3 fotos.'),
      );
    });

    test('un PDF reemplaza las fotos y una foto reemplaza el PDF', () {
      final photos = [_file('1.jpg'), _file('2.jpg')];
      final pdf = addPrescriptionFiles(photos, [_file('eps.pdf')]);
      expect(pdf.single.name, 'eps.pdf');
      final photo = addPrescriptionFiles(pdf, [_file('hoja.jpg')]);
      expect(photo.single.name, 'hoja.jpg');
    });

    test('no deja elegir un PDF con otros archivos', () {
      expect(
        () => addPrescriptionFiles([], [_file('a.pdf'), _file('b.jpg')]),
        _says('Elige un solo PDF, o fotos sin el PDF.'),
      );
    });

    test('el body manda tipo y base64', () {
      expect(_file('eps.pdf').toJson(), {
        'mime': 'application/pdf',
        'base64': 'AAAA',
      });
    });
  });

  group('PrescriptionPicker', () {
    Future<List<int>> pump(
      WidgetTester tester,
      List<PrescriptionAttachment> files,
    ) async {
      final removed = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PrescriptionPicker(
                user: null,
                files: files,
                onTakePhoto: () {},
                onPickFiles: () {},
                onRemove: removed.add,
              ),
            ),
          ),
        ),
      );
      return removed;
    }

    testWidgets('muestra el PDF y deja quitarlo', (tester) async {
      final removed = await pump(tester, [_file('formula-eps.pdf')]);

      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
      expect(find.textContaining('formula-eps.pdf'), findsOneWidget);
      await tester.tap(find.byTooltip('Quitar formula-eps.pdf'));
      expect(removed, [0]);
    });

    testWidgets('con 3 fotos apaga la cámara y lo dice', (tester) async {
      await pump(tester, [_file('1.jpg'), _file('2.jpg'), _file('3.jpg')]);

      final camera = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Otra hoja'),
      );
      expect(camera.onPressed, isNull);
      expect(
        find.text('Ya tienes 3 fotos. Quita una para cambiarla.'),
        findsOneWidget,
      );
    });

    testWidgets('sin archivos explica qué se acepta', (tester) async {
      await pump(tester, const []);

      expect(find.text('Tomar foto'), findsOneWidget);
      expect(find.text('Subir archivo'), findsOneWidget);
      expect(
        find.text('Un PDF o hasta 3 fotos, de 5 MB cada una.'),
        findsOneWidget,
      );
    });
  });
}
