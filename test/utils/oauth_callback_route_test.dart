import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/utils/router.dart';

void main() {
  group('OAuth callback route detection', () {
    test('recognizes the configured PKCE callback path', () {
      final uri = Uri.parse(
        'https://pawpal20.vercel.app/auth/callback?code=example',
      );

      expect(AppRouter.isOAuthCallbackUri(uri), isTrue);
    });

    test('recognizes a legacy fragment callback', () {
      final uri = Uri.parse(
        'https://pawpal20.vercel.app/#access_token=example&refresh_token=token',
      );

      expect(AppRouter.isOAuthCallbackUri(uri), isTrue);
    });

    test('does not treat an ordinary missing page as an OAuth callback', () {
      final uri = Uri.parse('https://pawpal20.vercel.app/missing');

      expect(AppRouter.isOAuthCallbackUri(uri), isFalse);
    });
  });
}
