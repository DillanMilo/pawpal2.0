# PawPal — Working Rules

**Read `docs/HANDOFF.md` before any non-trivial task.** It is the
operating brief for this project (goals, roadmap, decision criteria,
review checklist). This file is only the hard rules.

## Mission

Solo-founder pet-care app. Goal: App Store + Play Store v1, then ~20
real users. Feature-complete — remaining work is store readiness, not
architecture. Do not build for scale that doesn't exist.

## Hard conventions (each encodes a fixed bug)

- **Timestamps**: `toJson` → `.toUtc().toIso8601String()`; `fromJson` →
  `.toLocal()`; query filters compare in UTC. DATE columns (birth dates,
  medical dates) serialize date-only — never `.toUtc()` a calendar date.
- **Uploads**: `XFile` + `readAsBytes()` + `uploadBinary`. `dart:io` is
  banned in `lib/` (throws `Unsupported operation: _Namespace` on web).
- **Notification IDs**: `NotificationService.stableNotificationId()`,
  never `String.hashCode`. IDs 0/1 reserved (daily/streak). Reminder
  create/complete/delete/recur must each handle its notifications.
- **Dark mode**: use `AppTheme.cardBackground/primaryText/secondaryText/
  mutedText/borderFor/shadowFor(context)` — no hardcoded `Colors.white`
  backgrounds. Radii: 12/16/20/24/32.
- **Migrations**: numbered, additive, RLS in the same file. Dillan
  applies them **manually** in the Supabase SQL editor (CLI has no
  access) — flag new migrations loudly. The hosted DB is production.

## Verify before claiming done

```sh
flutter analyze && flutter test && flutter build web --release
```

`flutter clean` first if pubspec changed. Full checklist: HANDOFF.md §14.

## Deploy (web)

```sh
flutter build web --release
cp .vercel/project.json build/web/.vercel/project.json   # required
~/.hermes/node/bin/vercel deploy build/web --prod --yes  # NOT /usr/local/bin/vercel
```

Confirm `✓ Built build/web` before deploying — a failed build deploys
stale output. After deploying, remind Dillan to fully close the cached
tab on his phone.

## Secrets

`android/key.properties`, `~/pawpal-upload-key.jks`, `.env` — gitignored,
never commit, never print the keystore password (it lives in
`~/pawpal-upload-key-README.md`).

## Dillan

Dictates by voice (expect artifacts: "PowerPal" = PawPal, "Membranche" =
main branch). Wants commit + push to `main` when he asks, which is most
turns. Tests on the deployed web app from his phone. No test credentials
exist — never create accounts; state what you couldn't verify.
