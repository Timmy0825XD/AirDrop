import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/provider_retry.dart';
import 'package:frontend/core/api_exception.dart';

void main() {
  test('un 404 de Nest no se reintenta: se muestra de una vez', () {
    const notFound = ApiException('El pedido no existe.', statusCode: 404);

    expect(retryOnlyWithoutResponse(0, notFound), isNull);
  });

  test('sin respuesta del servidor reintenta 3 veces y para', () {
    final offline = ApiException.connection();

    expect(
      retryOnlyWithoutResponse(0, offline),
      const Duration(milliseconds: 200),
    );
    expect(
      retryOnlyWithoutResponse(2, offline),
      const Duration(milliseconds: 800),
    );
    expect(retryOnlyWithoutResponse(3, offline), isNull);
  });
}
