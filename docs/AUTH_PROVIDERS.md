# Google and Apple Login Setup

PawPal uses Supabase Auth for email/password, Google OAuth, and Apple OAuth.

## App values

Use these values consistently across Supabase, Google Cloud, Apple Developer, iOS, and Android:

| Setting | Value |
| --- | --- |
| Supabase project URL | `https://esrxaniydzgzxxxwzqca.supabase.co` |
| Supabase OAuth callback | `https://esrxaniydzgzxxxwzqca.supabase.co/auth/v1/callback` |
| iOS bundle ID | `com.creativecurrents.pawpal` |
| Android application ID | `com.creativecurrents.pawpal` |
| Native app redirect URL | `com.creativecurrents.pawpal://login-callback/` |
| Web OAuth callback path | `/auth/callback` |

## Supabase redirect URLs

In Supabase Dashboard > Authentication > URL Configuration:

1. Set the production Site URL to the deployed app URL.
2. Add these Additional Redirect URLs:
   - `com.creativecurrents.pawpal://login-callback/`
   - `com.creativecurrents.pawpal://**`
   - local development callback URLs you actively use, for example `http://127.0.0.1:8080/auth/callback`
   - the production callback URL, for example `https://your-production-domain.com/auth/callback`

## Google provider

1. In Google Cloud Console, create an OAuth client for the app.
2. Add this authorized redirect URI:
   - `https://esrxaniydzgzxxxwzqca.supabase.co/auth/v1/callback`
3. In Supabase Dashboard > Authentication > Providers > Google:
   - Enable Google.
   - Paste the Google client ID and client secret.
   - Save.

## Apple provider

1. In Apple Developer, create or confirm the App ID for:
   - `com.creativecurrents.pawpal`
2. Enable Sign in with Apple on the App ID.
3. Create a Services ID for the OAuth/web flow.
4. Configure the Services ID website return URL:
   - `https://esrxaniydzgzxxxwzqca.supabase.co/auth/v1/callback`
5. Generate an Apple client secret for the Services ID.
6. In Supabase Dashboard > Authentication > Providers > Apple:
   - Enable Apple.
   - Add the Services ID as the client ID.
   - Add the generated Apple client secret.
   - Save.

## App feature flags

Only enable the UI buttons after the Supabase providers are configured:

```env
APP_ENABLE_GOOGLE_AUTH=true
APP_ENABLE_APPLE_AUTH=true
```

On iOS and macOS, PawPal fails closed: Google is hidden unless Apple is also
enabled. This prevents an accidental App Store Guideline 4.8 violation while
the Apple Developer and Supabase provider setup is incomplete. Email/password
continues to work.

For Vercel or other hosted environments, set the same flags in the deployment environment.

## Code-side deep links

The app is configured for OAuth redirects with:

- iOS URL scheme in `ios/Runner/Info.plist`
- Android intent filter in `android/app/src/main/AndroidManifest.xml`
- OAuth redirect URL in `lib/services/auth_service.dart`

The Supabase Flutter SDK handles the returned OAuth callback and session recovery for deep links.
Web OAuth returns to `/auth/callback` so the auth fragment does not collide with Flutter hash routes such as `#/login`.
