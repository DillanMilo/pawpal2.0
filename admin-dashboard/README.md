# PawPal private admin

This Next.js surface hosts the authenticated `/admin` route and preserves the
existing Flutter web app at all customer-facing routes. It must be deployed to
the existing `pawpal2.0` Vercel project, never a separate public PawPal domain.

## Security model

- Admins sign in with a real Supabase Auth identity.
- `public.admin_users` is the explicit owner/admin allowlist.
- The Supabase service-role key is imported only by server modules and is never
  prefixed with `NEXT_PUBLIC_` or sent to the browser.
- RLS denies browser roles access to admin tables.
- Plan overrides are atomic, reasoned, optionally expiring, and audit logged.
  Store billing updates are retained while an override is active.
- Suspension is the normal reversible action. Permanent deletion requires the
  owner role and typing the user's email exactly.

## Required setup

1. Apply `supabase/migrations/014_admin_dashboard.sql`.
2. Deploy the updated `revenuecat-webhook` edge function.
3. Add exactly one reviewed owner UUID to `public.admin_users`.
4. Configure the four names in `.env.example` in Vercel. Never expose or copy
   the service-role value into a `NEXT_PUBLIC_*` variable.
5. Build Flutter web and copy its generated output into this app's `public/`
   directory before the Vercel build:

```sh
flutter build web --release
rsync -a --delete --exclude .gitkeep build/web/ admin-dashboard/public/
cd admin-dashboard
npm ci
npm test
npm run typecheck
npm run build
vercel build --prod
vercel deploy --prebuilt --prod
```

The middleware serves `/admin`, `/login`, and `/api/admin/*` through Next.js;
other application routes fall back to the staged Flutter `index.html`.
