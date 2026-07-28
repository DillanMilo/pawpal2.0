import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/utils/constants.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('iOS hides Google auth until Apple auth is enabled', () {
    dotenv.testLoad(
      fileInput: '''
APP_ENABLE_GOOGLE_AUTH=true
APP_ENABLE_APPLE_AUTH=false
''',
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(AppConstants.enableGoogleAuthForCurrentPlatform, isFalse);
    expect(AppConstants.enableAppleAuthForCurrentPlatform, isFalse);
  });

  test('iOS can offer Google when Apple auth is also enabled', () {
    dotenv.testLoad(
      fileInput: '''
APP_ENABLE_GOOGLE_AUTH=true
APP_ENABLE_APPLE_AUTH=true
''',
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(AppConstants.enableGoogleAuthForCurrentPlatform, isTrue);
    expect(AppConstants.enableAppleAuthForCurrentPlatform, isTrue);
  });

  test('Android may offer configured Google auth without Apple auth', () {
    dotenv.testLoad(
      fileInput: '''
APP_ENABLE_GOOGLE_AUTH=true
APP_ENABLE_APPLE_AUTH=false
''',
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(AppConstants.enableGoogleAuthForCurrentPlatform, isTrue);
  });
}
