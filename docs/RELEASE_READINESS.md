# PawPal Release Readiness

Updated July 28, 2026.

## Ready in the repository

- Flutter analysis and automated tests cover the release changes.
- CI may create an unsigned release APK for verification without receiving the
  Android upload key. Local and store release builds still require
  `android/key.properties`.
- iOS CI builds with `--no-codesign`.
- Public `/privacy`, `/terms`, and `/support` routes are bundled with the web
  and mobile apps.
- On Apple platforms, Google login is hidden unless Sign in with Apple is also
  enabled. Email/password remains available.
- Billing stays disabled until the store products, RevenueCat offering,
  webhook, and sandbox purchases are confirmed.
- Cloudflare R2 is private and bucket-scoped, with a 90-day lock and deletion
  after 180 days. The encrypted database-and-Storage recovery path passed its
  isolated restore drill, and nightly backups are enabled.

## Required owner actions

### Backup operations

The Supabase source credential, dedicated database role, independent
encryption passphrase, R2 destination, and GitHub secrets are configured.
Manual run `30404333546` verified backup `20260728T222318Z` through a complete
isolated database-and-Storage restore. Nightly backups are enabled.

The remaining operational action is to configure GitHub Actions failure
notifications for the recovery owner and repeat the hands-on recovery drill
quarterly.

### Apple Developer and TestFlight

1. In Apple Developer, enable Sign in with Apple for
   `com.creativecurrents.pawpal`.
2. Create the Services ID and client secret described in
   `docs/AUTH_PROVIDERS.md`, configure the Supabase Apple provider, then set
   `APP_ENABLE_APPLE_AUTH=true` for the iOS release.
3. Open `ios/Runner.xcworkspace` in Xcode, select the correct team, confirm the
   bundle ID and Sign in with Apple capability, and let Xcode create or select
   the distribution provisioning profile.
4. Archive on a Mac with the private signing identity. Uploading to TestFlight
   is a separate explicit release action and is not performed automatically.

### Google Play

1. Keep the upload keystore and `android/key.properties` outside Git and backed
   up in a second secure location.
2. Build the publishable bundle locally with `flutter build appbundle --release`.
   The CI APK is intentionally unsigned and must not be uploaded.
3. Enroll in Play App Signing on the first internal-track upload.

### Required hands-on testing

- On a physical iPhone, create a reminder due in five minutes, background the
  app, and verify both notification times and tap navigation.
- Repeat the reminder test on a physical Android device, including after a
  restart if exact alarms are enabled.
- Exercise account creation, export, and deletion on the production candidate.
- Verify the public Privacy, Terms, and Support URLs before entering them in
  App Store Connect and Play Console.

No store submission, TestFlight upload, paid plan activation, or live billing
enablement should occur without explicit owner confirmation.
