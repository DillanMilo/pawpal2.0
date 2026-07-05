# PawPal 🐾

Your all-in-one pet management companion. Track your pets' care, health records, activities, appointments, and reminders — for iOS, Android, and web.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| App | Flutter (Dart), Provider, GoRouter |
| Backend | Supabase (Auth, PostgreSQL + RLS, Storage, Edge Functions) |
| Notifications | flutter_local_notifications (device-local scheduling) |
| Places | Google Places API via Supabase edge-function proxy |
| Web hosting | Vercel |

## Getting Started

1. Install [Flutter](https://docs.flutter.dev/get-started/install) 3.10+.
2. Create a Supabase project and apply every migration in `supabase/migrations/` **in order** (SQL Editor, or `supabase db push` with a linked CLI).
3. Create the storage buckets: `profile-photos`, `pet-photos`, `medical-documents` (private), `activity-photos`.
4. Copy `.env.example` to `.env` and fill in your credentials.
5. Run:

```sh
flutter pub get
flutter run
```

## Tests

```sh
flutter analyze
flutter test
```

## Deploying the web app

```sh
flutter build web --release
vercel deploy build/web --prod
```

## Documentation

- [docs/BACKEND.md](docs/BACKEND.md) — schema, RLS policies, services, integrations
- [docs/PROGRESS.md](docs/PROGRESS.md) — development phase log
- [docs/FEATURES.md](docs/FEATURES.md) — feature overview
- [docs/ROADMAP.md](docs/ROADMAP.md) — what's next
