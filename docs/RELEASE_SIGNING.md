# Release Signing & API Key Security

> Last updated: 2026-07-05. The keystore and passwords referenced here are
> **not** in git — this doc only tells you where they live and what to do
> with them.

---

## 1. Android upload keystore — ALREADY DONE ✅

The upload keystore was generated on 2026-07-05. You do **not** need to
create anything. Current state:

| What | Where |
|------|-------|
| Keystore file | `~/pawpal-upload-key.jks` (your home folder) |
| Format | PKCS12, RSA 2048, alias `upload`, cert valid to Nov 2053 |
| Passwords + config | `android/key.properties` (gitignored, owner-only permissions) |
| **Personal reference (includes the password)** | **`~/pawpal-upload-key-README.md`** — full plain-English guide kept next to the keystore, deliberately outside this repo so the password can never reach GitHub |

The Gradle build reads `android/key.properties` automatically. Release
builds are signed with this key; if the file is missing, the build fails
loudly instead of falling back to debug signing.

### ⚠️ The one thing you MUST do: back it up

If you lose `~/pawpal-upload-key.jks` **and** its password, you cannot
update PawPal on the Play Store under the same listing (unless enrolled in
Play App Signing — see below, you should enroll).

1. Open `android/key.properties` in any editor — the `storePassword` line
   is the keystore password.
2. Save the password in your password manager (entry name: "PawPal Android
   upload keystore").
3. Copy `~/pawpal-upload-key.jks` somewhere durable that is **not** this
   laptop — e.g. attach it to the same password-manager entry, or put it in
   iCloud Drive / an encrypted backup. Never commit it to git.

### First Play Store upload

When you create the app in Play Console, opt in to **Play App Signing**
(it's the default). Google then holds the real signing key and your
keystore is just the "upload key" — if you ever lose it, you can ask
Google to reset it instead of losing the listing. This is your safety net;
take it.

### Building a signed release

This machine currently has **no Java runtime / Android SDK**, so Android
builds won't run here yet. Either:

- **Install Android Studio** (https://developer.android.com/studio), open
  it once so it installs the SDK, then run `flutter doctor` and accept
  licenses (`flutter doctor --android-licenses`). After that:

  ```sh
  flutter build appbundle --release
  # output: build/app/outputs/bundle/release/app-release.aab
  ```

- Or build in CI (GitHub Actions) by adding the keystore as a base64
  secret. Ask Claude to wire this up when you're ready to automate
  releases.

### If you ever need to regenerate the keystore

Only do this before your first Play upload, or after a Play App Signing
upload-key reset. With Android Studio installed:

```sh
keytool -genkey -v -keystore ~/pawpal-upload-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then update `storePassword`/`keyPassword` in `android/key.properties`.

---

## 2. Google Places API key restriction

The app's Places key (starts `AIzaSyCB`, ends `FRFg`) is called by the
Supabase edge function `places-proxy` — requests come from Supabase's
servers, **not** from phones. So:

- **DO** restrict which APIs the key can call.
- **DO NOT** add Android/iOS application restrictions — that would break
  the proxy. Leave "Application restrictions" on **None**.

### Exact steps

1. Go to https://console.cloud.google.com/apis/credentials and make sure
   the project picker (top bar) shows the **PawPal** project.
2. There is one API key there: **"Browser key (auto created by Firebase)"**.
   Click **Show key** and confirm it ends in `FRFg` — that's the app's key.
3. Click the key's name to edit it.
4. It already has an API restriction list (Firebase added ~25 of its own
   APIs). In the **API restrictions** dropdown, make sure these two are
   checked **in addition to** whatever is already there:
   - **Places API** (the classic one — *not* "Places API (New)"; the app
     calls the classic endpoints)
   - **Geocoding API**

   Don't remove the pre-existing Firebase entries — adding to the list is
   safe, removing could break something that still uses the key.
5. Click **Save**. Takes effect within a few minutes.

### Verify nothing broke

Open the deployed app → Discover tab → search providers by zip code. If
results load, the restriction is correct. If you get errors, re-open the
key and confirm the two APIs above are checked.

### One more hardening step (recommended, 5 min)

The same key sits in the app's local `.env`, which means older mobile
builds shipped it inside the binary. Since the proxy is the only thing
that should use it now:

1. Create a **new** API key in the same Google Cloud project, restricted
   the same way.
2. In Supabase Dashboard → Edge Functions → `places-proxy` → Secrets, set
   `GOOGLE_PLACES_API_KEY` to the new key.
3. Delete the old key in Google Cloud.
4. Remove/blank the `GOOGLE_PLACES_API_KEY` line in your local `.env` —
   the Flutter app doesn't need it anymore (it goes through the proxy).
