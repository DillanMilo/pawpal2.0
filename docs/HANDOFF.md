# PawPal — Successor Model Handoff

> Written 2026-07-09 by the outgoing model after a full audit, fix, and
> ship cycle on this codebase. You are reading this because you are the
> new model helping Dillan. Read all of it once, then keep §15 in your
> head permanently. This is an operating brief, not documentation —
> `docs/BACKEND.md` and `docs/RELEASE_SIGNING.md` cover mechanics.

---

## 1. What this project is really trying to accomplish

PawPal is a pet-care companion app (pets, medical records, activity
tracking with points/streaks, reminders, appointments, provider
discovery). Flutter for iOS/Android with a web build used as the test
surface, Supabase as the entire backend (no custom server), deployed to
Vercel at pawpal20.vercel.app.

The *actual* goal is narrower than the feature list suggests: **get a
polished v1 into the App Store and Play Store, then get ~20 real pet
owners using it.** Dillan is a solo founder (Creative Currents) who ships
fast with AI help but is not a mobile-release-ops expert. Every session
should move the app toward "live in stores" or keep it healthy. The app
is feature-complete for v1. The remaining distance is operational
(builds, listings, device testing), not architectural.

Your job is to be the engineer who finishes things, not the architect
who starts them.

## 2. The highest leverage next steps (in order)

1. **Physical-device test of reminder notifications.** The notification
   stack was rebuilt in July 2026 (see §6) but has never been verified on
   real hardware. Simulators don't exercise exact alarms or boot
   receivers. Until a reminder fires on Dillan's actual phone, treat
   notifications as unproven. Walk him through: create a reminder due in
   5 minutes, background the app, confirm both alerts.
2. **The Sign-in-with-Apple decision (store blocker).** Google OAuth is
   enabled (`APP_ENABLE_GOOGLE_AUTH=true` in `.env`) and Apple is not.
   App Store Guideline 4.8: an iOS app offering third-party login (Google)
   **must** also offer Sign in with Apple. Either configure Apple auth
   (Apple Developer + Supabase provider, see `docs/AUTH_PROVIDERS.md`) or
   set `APP_ENABLE_GOOGLE_AUTH=false` for the iOS build. Email-only v1 is
   the low-friction path; make Dillan choose, don't choose for him.
3. **Privacy policy URL.** Both stores require one; none exists. A static
   page (could live on the Vercel deploy or creativecurrents.io) covering
   what's collected (email, name, pet data, photos, coarse location for
   provider search) is a 1-hour task that blocks everything downstream.
4. **Android Studio install → first signed `flutter build appbundle`.**
   The Mac has no Java/Android SDK. Keystore + `key.properties` are
   already in place (see `docs/RELEASE_SIGNING.md`). Until Android Studio
   is installed, no local Android build is possible.
5. **Store listings**: screenshots, descriptions, data-safety forms, age
   rating. Tedious, high-value, easy to assist with.
6. Only after all the above: TestFlight / Play internal testing with
   ~10 pet-owner friends.

Do not start new features while any of 1–5 is open.

## 3. What NOT to overbuild

These were considered deliberately and rejected. Don't relitigate them
without new evidence:

- **Firebase / FCM.** All notifications are personal and device-local.
  FCM adds APNs certs, config files, and a sender backend while fixing
  nothing. Revisit only when a *server* needs to initiate a push
  (cross-user features, clinic integrations).
- **Offline-first sync engine.** Current model: 5-min TTL cache +
  graceful offline banner. Good enough until real users complain.
- **Server-side aggregation RPCs / pagination.** Points and streaks are
  summed client-side. At <1k activities per user this is fine. The
  migration hook exists (`supabase/migrations/`) when it isn't.
- **State-management migration.** It's Provider. It stays Provider.
  Riverpod/Bloc migration is a week of churn for zero user value.
- **Web polish beyond what exists.** The web target is a demo/testing
  surface. Auth screens are width-constrained, there's a branded loader —
  that's enough. The product is the mobile apps.
- **CI release automation.** First releases should be manual. Automate
  signing in CI only after release #2 or #3.
- **Design-system completionism.** Tokens and dark-mode helpers exist
  (`lib/utils/theme.dart`). Use them in code you touch; do not sweep the
  codebase again.

The consistent failure mode to resist: building for imaginary scale.
Current user count is zero.

## 4. Core user workflows (protect these)

1. **Onboard**: register (email/password) → land on home → "Add Your
   First Pet" card → pet profile created.
2. **Daily loop**: open app → home shows pets, streak, points, upcoming
   reminders → log activity (quick action or timer FAB) → points/streak
   update. Gamification is the retention hook; anything that breaks the
   streak calculation breaks the product's core promise.
3. **Reminders**: create (title/type/time, optional recurrence) → local
   notifications at T-1h and T-0 → complete/delete cancels them →
   recurring completion schedules the next occurrence.
4. **Medical**: per-pet records by type (vaccination, medication, …) with
   due dates. Document upload service is web-safe but has no UI yet.
5. **Passport**: QR + share sheet for a pet's info.
6. **Discover**: nearby vets/groomers/stores via the `places-proxy` edge
   function (GPS or zip).

If a change touches workflows 2 or 3, test it end-to-end before calling
it done.

## 5. Key risks and unknowns

- **Notifications unverified on hardware** (§2.1). Biggest correctness
  unknown in the app.
- **Keystore backup is on Dillan.** `~/pawpal-upload-key.jks` + password
  in `~/pawpal-upload-key-README.md`. If he hasn't backed them up and the
  laptop dies pre-Play-App-Signing-enrollment, the Play listing is
  orphaned. Nag him once per session until he confirms.
- **Supabase CLI cannot reach the project** (logged into a different
  account than the one owning project `esrxaniydzgzxxxwzqca`). All
  migrations are applied by Dillan manually in the SQL editor. 001–009
  are applied as of 2026-07-06. Never write client code that depends on
  an unapplied migration; always tell him explicitly when a new migration
  file needs running.
- **Supabase free tier pauses inactive projects.** If "everything is
  down," check the Supabase dashboard before debugging code.
- **`places-proxy` has `verify_jwt=false`** (needed for photo URLs).
  Google API key sits server-side and is API-restricted, so worst case is
  quota abuse. Acceptable now; add rate limiting if bills appear.
- **Achievements are half-built.** Badge catalog and thresholds exist
  (`lib/models/achievement.dart`, profile shows milestone progress) but
  no service ever *awards* rows to the `achievements` table. Known gap,
  fine for v1 — the profile computes progress live. Don't "discover" this
  as a bug; decide with Dillan when to finish it.
- **Old test data predates the July timezone fix** and may display
  shifted. Wipe test data rather than chasing phantom date bugs.
- **A stray Vercel project named "web"** serves a stale copy of PawPal
  (`web-dusky-eight-86.vercel.app`). Dillan hasn't deleted it. Deleting
  is his call.
- **iOS local build status unknown.** CI builds iOS with `--no-codesign`;
  whether this Mac has Xcode configured for device builds is unverified.
  Run `flutter doctor` before promising an iOS build.

## 6. Technical architecture guidance

Layers: `screens/ → providers/ (Provider ChangeNotifiers) → services/ →
Supabase`. Models in `models/` own all JSON mapping. Security lives
entirely in Postgres RLS — the anon key ships in the client by design.

**Non-negotiable conventions** (each one encodes a fixed bug; violating
them reintroduces it):

1. **Timestamps**: `toJson` writes `.toUtc().toIso8601String()`;
   `fromJson` parses then `.toLocal()`. Query filters compare in UTC.
   DATE columns (pet birth/adoption dates, medical dates) serialize as
   date-only strings (`_dateOnly`) — never `.toUtc()` a calendar date.
2. **Uploads**: `XFile` + `readAsBytes()` + `uploadBinary`. Never
   `dart:io File` — it throws `Unsupported operation: _Namespace` on web
   (Dillan's primary test surface). There are zero `dart:io` imports in
   `lib/` today; keep it that way.
3. **Notification IDs**: `NotificationService.stableNotificationId()`
   (FNV-1a). Never `String.hashCode` (not stable across launches →
   uncancellable notifications). Reserved IDs: 0 = daily reminder,
   1 = streak reminder.
4. **Reminder lifecycle**: create → schedule against the *returned*
   reminder (it has the real id); complete/delete → cancel notifications;
   recurring complete → `markAsCompleted` returns `(completed, next)` —
   schedule `next`.
5. **Dark mode**: `AppTheme.cardBackground/primaryText/secondaryText/
   mutedText/borderFor/shadowFor(context)`. Hardcoded `Colors.white` is
   only for foregrounds on colored/gradient backgrounds.
6. **Radii**: 12/16/20/24/32 (documented in theme.dart).
7. **Migrations**: numbered, additive, `IF NOT EXISTS`. New tables get
   RLS enabled + owner-scoped policies in the same file.

**Operational quirks that will bite you:**

- Web deploy: `flutter build web --release`, then copy
  `.vercel/project.json` into `build/web/.vercel/`, then
  `vercel deploy build/web --prod --yes`. Skipping the copy deploys to
  the wrong project ("web"). Use the CLI at
  `~/.hermes/node/bin/vercel` — `/usr/local/bin/vercel` is an ancient
  root-owned v39 that shadows it in PATH and fails deploys.
- After removing/adding pubspec dependencies, run `flutter clean` before
  `flutter build web` — stale plugin registrants break the compile while
  `flutter analyze` stays green.
- Flutter web service-worker caching: when Dillan says "still broken on
  my phone" right after a deploy, have him fully close and reopen the
  tab before you debug anything.
- iOS privacy manifest is registered directly in `project.pbxproj`
  (entries `A1B2C3D4E5F60718293A4B5C/5D`). Edit that file surgically or
  through Xcode only.

## 7. Product and business strategy guidance

- **The near-term customer is the App Store reviewer.** Decisions filter
  through "would this survive review?" — no dead UI, no placeholder
  data, working account deletion (exists), privacy manifest (exists),
  privacy policy (missing).
- **The wedge is simplicity + charm**, not feature count. Rover, 11pets,
  and PetDesk exist; PawPal wins on the 30-second "log a walk, keep the
  streak" loop and a warm brand (soft lavender #9D7BEA, ink #171717,
  Outfit font, rounded surfaces, paw motif). Reject features that make
  the daily loop heavier.
- **Free at launch, no monetization plumbing yet.** Don't add
  subscriptions, ads, or analytics SDKs unprompted. When revenue comes
  up, the natural line is premium care features (multi-caregiver
  sharing, vet export) — but that's post-traction.
- **90-day success metric**: live in both stores, 20 real users, some
  evidence of week-2 retention (streaks are the proxy).
- Dillan runs several other projects (RailCommand, Creative Currents
  clients). Sessions are bursty. End every work session with everything
  committed, pushed, and deployed — never leave the repo mid-surgery.

## 8. Good decisions vs bad decisions

A decision is good here when it:
- ships value to the store-readiness path or fixes a real observed bug;
- is the smallest change that fully solves the problem (fix + its
  lifecycle: the reminder bug wasn't fixed until create/complete/delete/
  recur all handled notifications);
- follows §6 conventions without inventing new ones;
- can be verified today (analyzer + tests + a runnable surface);
- leaves the repo deployable.

A decision is bad when it:
- adds a dependency, abstraction layer, or service for a hypothetical;
- refactors working code "while I'm here" (formatter-only diffs excepted);
- optimizes for >1k users while user count is 0;
- requires backend changes Dillan must apply manually but doesn't say so
  loudly;
- trusts a subagent's or its own claim without reading the actual code
  (the July audit found several confidently-wrong agent findings — e.g.
  a "missing RLS policy" that was covered by a `FOR ALL` policy, and a
  "missing account deletion" that existed with a confirmation dialog).

Litmus test: *"Does this get PawPal closer to two store listings and 20
happy users, or does it make the codebase more impressive?"* Only the
first matters.

## 9. How to review future work on this project

For any diff (yours, Cursor's, or another model's):

```sh
flutter analyze                      # must be zero issues
flutter test                         # 143+ tests, all green
flutter build web --release          # web must still compile
```

Then grep the diff for the known bug classes:

```sh
grep -rn "dart:io" lib/                                  # must be empty
grep -rn "\.hashCode" lib/services/ lib/screens/          # no ID derivation
grep -rnE "toIso8601String\(\)" lib/ | grep -v "toUtc\|_dateOnly"  # suspicious
grep -rn "color: Colors.white,$" lib/screens/ lib/widgets/ # new dark-mode breaks
grep -rn "PlaceholderData" lib/screens/                   # demo data creep
```

Manual passes: both themes for touched screens, empty states (new user
with zero pets/activities), and end-to-end for anything touching
reminders or streaks. New tables → confirm RLS in the migration. New
env vars → `.env.example` updated. If a migration was added → tell
Dillan to run it, in bold, at the top of your summary.

## 10. What to be especially careful about

- **Secrets and `git add -A`.** `android/key.properties`, `*.jks`, and
  `.env` are gitignored, but verify with `git status` before every
  commit that sweeps files. The keystore password lives ONLY in
  `~/pawpal-upload-key-README.md` and `android/key.properties` — it must
  never appear in the repo, the chat, or a committed doc.
- **Don't deploy a stale `build/web`.** A failed build followed by
  `vercel deploy` ships the previous build silently. Confirm
  `✓ Built build/web` before deploying.
- **Voice-input artifacts.** Dillan dictates: "PowerPal" = PawPal,
  "Membranche" = main branch, "unsupported_namespace" = `Unsupported
  operation: _Namespace`. Interpret generously; confirm only if truly
  ambiguous.
- **He expects commit + push when he says so** — and he says so almost
  every turn. Run the full verify suite first, write real commit
  messages, push to `main` (solo dev, no PR flow).
- **The hosted DB is production.** There are no environments. Any SQL
  you hand him runs against the only database. Keep migrations additive;
  never hand him destructive SQL without spelling out what it deletes.
- **You cannot log into the app** (no test credentials; don't create
  accounts). Verification beyond the login screen is static analysis +
  tests + Dillan's hands. Be explicit about that boundary in what you
  claim as "verified."

## 11. Questions to ask Dillan before acting

- Anything destructive or irreversible: deleting the stray "web" Vercel
  project, rotating API keys, wiping test data, dropping columns.
- The Sign-in-with-Apple vs email-only decision (§2.2).
- Anything that costs money: Apple Developer / Play Console fees, paid
  Supabase tier, new services.
- Before assuming a migration is applied: "did you run 0XX in the SQL
  editor?"
- Store-listing copy/brand decisions bigger than a tweak — the brand is
  his.
- Whether he's backed up the keystore (once per session until yes).

## 12. What to do without asking

- Fix observed bugs, add tests, keep the analyzer at zero.
- Follow the §6 conventions in any code you touch (including dark-mode
  and accessibility corrections in files you're already editing).
- Run analyze/test/build before claiming done — always.
- Update docs (`PROGRESS.md`, `BACKEND.md`, this file) when reality
  changes.
- Redeploy the web app after fixing something he reported on web —
  that's the established pattern.
- Commit and push when he asks in the turn (he will).

## 13. Execution roadmap

**Phase A — prove it works (this week):** notification test on his
phone; Apple-sign-in decision; privacy policy page live at a URL;
Android Studio installed; first signed `.aab` builds locally.

**Phase B — submit:** Play Console + App Store Connect accounts;
listings, screenshots (web build in device frames is acceptable v1),
data-safety forms; TestFlight + Play internal track; fix what reviewers
and testers surface. Enroll Play App Signing at first upload.

**Phase C — soft launch and learn:** ~10 friendly pet owners; watch
streak retention; fix the top 3 complaints; only then consider new
features. Queue for post-launch, roughly in value order: wire medical
document upload UI (service is ready), finish achievements awarding,
activity photos, appointment↔reminder linking, CI release automation.

## 14. Review checklist for future Claude Code / Cursor work

- [ ] `flutter analyze` — zero issues
- [ ] `flutter test` — all green (143+ as of July 2026)
- [ ] `flutter build web --release` compiles (after `flutter clean` if
      pubspec changed)
- [ ] No `dart:io` in `lib/`
- [ ] Timestamps: UTC on write, local on read; DATE columns date-only
- [ ] Notification IDs via `stableNotificationId`; lifecycle handled on
      create/complete/delete/recur
- [ ] Touched screens checked in light AND dark mode; theme helpers used
- [ ] Empty states survive a brand-new user (no pets, no data)
- [ ] No placeholder/demo data wired into real screens
- [ ] New tables: RLS enabled + policies in the same migration; Dillan
      told to run it
- [ ] `git status` clean of secrets before commit; pushed to `main`
- [ ] If web-facing: rebuilt and redeployed (with the `.vercel` copy
      step), and Dillan told to hard-close the cached tab

## 15. If you only remember five things

1. **The mission is two store listings and 20 real users** — every
   session should shorten that distance, not beautify the codebase.
2. **UTC on write, local on read, date-only for DATE columns; XFile
   bytes for uploads, never `dart:io`** — these two conventions encode
   the worst bugs this app ever had.
3. **Verify before you claim**: analyze + test + build, read the actual
   code before trusting any finding (including your own subagents'), and
   say plainly what you could not verify.
4. **The backend is one production Supabase project Dillan migrates by
   hand** — never ship client code that needs SQL he hasn't run, and
   never hand him destructive SQL casually.
5. **He ships by voice from his phone half the time**: interpret
   transcription artifacts generously, commit-push-deploy when asked,
   and leave the repo in a state where walking away is safe.
