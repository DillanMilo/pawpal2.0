# PawPal 2.0 Roadmap

> Last updated: 2026-08-26

---

## Completed

### Phase 1: Foundation
- [x] Project setup (Flutter 3.10+, Supabase backend)
- [x] User authentication (email/password, Google OAuth, Apple OAuth)
- [x] Navigation structure (GoRouter with auth guards, bottom nav shell)
- [x] Pet profile CRUD (list, detail, add, edit screens)
- [x] Home page (dashboard with carousel, stats, daily tips)

### Phase 2: Core Features
- [x] Medical history management (vaccinations, medications, allergies, vet visits, surgeries, lab results)
- [x] Pet Passport generation (QR code with configurable privacy, native sharing)
- [x] Calendar and appointments (monthly/weekly view, appointment creation)
- [x] Activity logging (8 types, timer + manual entry, points system)
- [x] Provider discovery UI (tabbed view for vets, groomers, pet stores)

### Phase 3: Polish & Gamification
- [x] Gamification system (points per activity, streak tracking, 6+ badge types)
- [x] Activity dashboard (fl_chart weekly chart widget)
- [x] Activity history (filter by type/date, grouped by day)
- [x] Push notifications (local notifications, scheduled reminders, streak alerts)
- [x] Reminders (create with due dates, recurring patterns, filter by status)

### Phase 4: Stability & Security (2026-04-04)
- [x] Fixed build-breaking geolocator API mismatch
- [x] Pinned `intl` dependency to `^0.20.0`
- [x] Migrated hardcoded API keys to `flutter_dotenv` (`.env` file)
- [x] Added `.env` to `.gitignore`, created `.env.example`
- [x] Optimized `getCurrentStreak()` — single DB query (was up to 365)
- [x] Global error handler (`ErrorWidget.builder` for release mode)
- [x] 404/error route in GoRouter (`/not-found` with Go to Home)
- [x] Improved input validation (RFC-compliant email regex, 8-char password minimum)

### Phase 5: Accessibility & UX (2026-04-04)
- [x] Added `Semantics` widgets to all interactive elements (~26 files)
- [x] Replaced 40+ `GestureDetector`s with `InkWell` + `Semantics`
- [x] Added tooltips to all icon-only buttons throughout the app
- [x] Fixed color contrast (`textLight` updated to WCAG AA compliant `#6B7280`)
- [x] Implemented dark theme (auto-switches based on system settings)
- [x] Decomposed `HomeScreen` into 3 extracted widgets + fixed scroll perf with `ValueNotifier`

### Phase 6: Feature Completion (2026-04-04)
- [x] Notification tap navigation (payload-based routing via GoRouter)
- [x] Medical record editing (reused add screen with pre-filled data)
- [x] Pet sharing (formatted text summary via `share_plus`)
- [x] Passport export (formatted text passport respecting privacy toggles)
- [x] Notification preference persistence (SharedPreferences with master + sub-toggles)
- [x] Full Google Places API integration (GPS location, zipcode fallback, pull-to-refresh)
- [x] Offline mode (connectivity helper, graceful degradation, auto-dismissing banner)
- [x] Data caching with 5-min TTL in PetProvider and ActivityProvider
- [x] Comprehensive `docs/BACKEND.md` documentation

### Phase 7: Testing & CI/CD (2026-04-04)
- [x] 154 tests passing across models, providers, widgets, services, and constants
- [x] Test helpers: `FakeAuthProvider`, `createTestWidget`, `supabase_test_setup`
- [x] GitHub Actions CI/CD pipeline (analyze + test, build Android APK, build iOS)
- [x] Pull request template (`.github/PULL_REQUEST_TEMPLATE.md`)

### Phase 8: Dependency Maintenance (2026-04-04)
- [x] Updated `share_plus` 7.x -> 10.x (migrated to `SharePlus.instance.share()` API)
- [x] Updated `mobile_scanner` 4.x -> 6.x
- [x] Updated `flutter_local_notifications` 17.x -> 19.x (removed deprecated params)
- [x] Updated `connectivity_plus` 5.x -> 6.x
- [x] Replaced abandoned `qr_flutter` with `pretty_qr_code`
- [x] Migrated 50 deprecated `withOpacity()` calls to `withValues(alpha:)` across 12 files

---

## Remaining Items

Small items deferred from completed phases:

- [ ] Network connectivity checks before write operations (reads handled, writes fail naturally)
- [ ] Error logging service (Sentry or Firebase Crashlytics)
- [ ] Expand test coverage toward 70%+ (foundation of 154 tests in place)
- [x] Full account data export with original uploaded documents
- [ ] Fix Grooming search results so ordinary pet shops are not shown as
  groomers

---

## Future Enhancements

Ideas for post-v2 development. Not yet scheduled or prioritized.

### Social & Community
- [ ] Pet community feed (share photos, milestones)
- [ ] Friend system (connect with other pet owners)
- [ ] Social activity challenges (group walking events)

### Health & Analytics
- [ ] Pet health insights dashboard (weight trends, activity patterns, medical timeline)
- [ ] Preventive-care reminder presets for tick/flea prevention, vaccinations,
  medication refills and expirations, and deworming
- [ ] AI-powered health recommendations based on breed and activity data
- [ ] Veterinary report generation (exportable health summary for vet visits)

### Platform & Reach
- [ ] Multi-language support (i18n/l10n)
- [ ] Web app version (Flutter web)
- [ ] Tablet-optimized layouts

### Integrations
- [ ] Pet insurance provider integration
- [ ] Wearable device support (FitBark, Whistle, Fi collar)
- [ ] Smart feeder integration
- [ ] Telehealth/virtual vet consultation booking
- [ ] Boarding and daycare discovery for kennels, pet hotels, and doggy daycare

### Monetization
- [x] Subscription/trial architecture and server-owned entitlements
- [ ] Complete provider setup and production billing checklist in `MONETIZATION.md`
- [ ] Complete database and Storage recovery gate in `BACKUP_RECOVERY.md`
- [ ] Premium tier with advanced analytics
- [ ] In-app pet supply marketplace
- [ ] Sponsored provider listings
- [ ] Validate a provider booking/referral pilot before considering marketplace
  payments and booking commissions

See `PRODUCT_ROADMAP.md` for the reliability, household, AI, and integration
sequence that should follow the initial Plus launch. See
`FUTURE_ENDEAVORS.md` for the beta-feedback proposal covering grooming search
quality, preventive-care reminders, boarding discovery, and a possible booking
marketplace.
