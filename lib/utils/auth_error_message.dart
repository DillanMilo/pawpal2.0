import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

const authConnectionErrorMessage =
    'We couldn\'t connect to PawPal. Check your internet connection and try again.';
const authUnexpectedErrorMessage =
    'Something went wrong. Please try again in a moment.';

String authErrorMessage(Object error) {
  if (error is AuthRetryableFetchException) {
    return authConnectionErrorMessage;
  }
  if (error is AuthUnknownException &&
      (error.originalError is http.ClientException ||
          error.originalError is TimeoutException)) {
    return authConnectionErrorMessage;
  }
  if (error is AuthException) return error.message;
  if (error is http.ClientException || error is TimeoutException) {
    return authConnectionErrorMessage;
  }
  return authUnexpectedErrorMessage;
}
