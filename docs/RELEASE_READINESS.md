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
  after 180 days. Scheduled backups remain disabled pending source secrets and
  a verified recovery run.

## Required owner actions

### Supabase backup source

Sign in to the Supabase account that owns project
`esrxaniydzgzxxxwzqca`, then:

1. Storage > Settings > S3 Access Keys: create a server-only access key.
2. Add its two values as GitHub Actions repository secrets:
   `PAWPAL_SOURCE_S3_ACCESS_KEY_ID` and
   `PAWPAL_SOURCE_S3_SECRET_ACCESS_KEY`.
3. Add the direct or session-pooler PostgreSQL connection string as
   `PAWPAL_DATABASE_URL`. Do not place the database password in the repository.
4. Generate a long random encryption passphrase, save it in an independent
   password manager, and add it as
   `PAWPAL_BACKUP_ENCRYPTION_PASSPHRASE`.
5. Run **PawPal Backup** manually, verify the uploaded encrypted archive with
   `scripts/backup/verify_backup.sh`, and perform an isolated restore drill.
6. Only then create `PAWPAL_BACKUPS_ENABLED=true` in GitHub Actions variables.

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
