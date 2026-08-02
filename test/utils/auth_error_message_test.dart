import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/utils/auth_error_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('preserves safe authentication messages from Supabase', () {
    expect(
      authErrorMessage(const AuthException('Email is already registered')),
      'Email is already registered',
    );
  });

  test('replaces network exception details with a useful message', () {
    final message = authErrorMessage(
      http.ClientException('Failed host lookup: test.supabase.co'),
    );

    expect(message, authConnectionErrorMessage);
    expect(message, isNot(contains('test.supabase.co')));
  });

  test('replaces retryable Supabase network errors', () {
    expect(
      authErrorMessage(
        AuthRetryableFetchException(message: 'upstream network detail'),
      ),
      authConnectionErrorMessage,
    );
  });

  test('replaces wrapped Supabase client errors', () {
    expect(
      authErrorMessage(
        AuthUnknownException(
          message: 'request failed',
          originalError: http.ClientException('private network detail'),
        ),
      ),
      authConnectionErrorMessage,
    );
  });

  test('does not expose unexpected exception details', () {
    expect(
      authErrorMessage(Exception('internal implementation detail')),
      authUnexpectedErrorMessage,
    );
  });
}
