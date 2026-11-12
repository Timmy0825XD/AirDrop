import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_base_url.dart';

void main() {
  group('resolveApiBaseUrl en desarrollo', () {
    test('sin dirección usa el PC desde el emulador de Android', () {
      expect(
        resolveApiBaseUrl(
          configured: '',
          release: false,
          web: false,
          android: true,
        ),
        'http://10.0.2.2:3000',
      );
    });

    test('sin dirección usa localhost en web y escritorio', () {
      expect(
        resolveApiBaseUrl(
          configured: '',
          release: false,
          web: true,
          android: false,
        ),
        'http://localhost:3000',
      );
      expect(
        resolveApiBaseUrl(
          configured: '',
          release: false,
          web: false,
          android: false,
        ),
        'http://localhost:3000',
      );
    });

    test('respeta una dirección configurada, también HTTP', () {
      expect(
        resolveApiBaseUrl(
          configured: 'http://192.168.1.20:3000',
          release: false,
          web: false,
          android: true,
        ),
        'http://192.168.1.20:3000',
      );
    });
  });

  group('resolveApiBaseUrl en release (H-02)', () {
    test('acepta HTTPS y quita la barra final', () {
      expect(
        resolveApiBaseUrl(
          configured: ' https://api.airdrop.test/ ',
          release: true,
          web: false,
          android: true,
        ),
        'https://api.airdrop.test',
      );
    });

    test('rechaza HTTP', () {
      expect(
        () => resolveApiBaseUrl(
          configured: 'http://api.airdrop.test',
          release: true,
          web: false,
          android: true,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            releaseNeedsHttps,
          ),
        ),
      );
    });

    test('sin dirección no cae en el backend local por HTTP', () {
      expect(
        () => resolveApiBaseUrl(
          configured: '',
          release: true,
          web: false,
          android: true,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
