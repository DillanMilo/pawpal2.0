# PawPal Monetization Architecture

> Launch design as of 2026-07-21. Billing stays disabled until every item in
> the production checklist is complete.

## Product and pricing decision

| Plan | Price | Launch limits |
|---|---:|---|
| PawPal Base | $0 | 1 pet, 5 active one-time reminders, 20 medical records |
| PawPal Plus Monthly | $4.99/month | Unlimited pets, records, reminders, and Plus features |
| PawPal Plus Annual | $29.99/year | Same features; approximately 50% below monthly billing |

Every new account receives 14 days of Plus without entering payment details.
The trial does **not** automatically renew. If the user does not subscribe, the
account returns to Base and existing data remains readable. Full account export is
a launch-gate item before paid limits are enabled broadly.

Do not configure a second introductory trial in App Store Connect, Play
Console, Stripe, or RevenueCat. PawPal owns trial eligibility in PostgreSQL so
the same account cannot receive separate trials from multiple platforms.

## User experience

1. Registration advertises `Sign Up Free`, the 14-day trial, prices, and the
   fact that there is no automatic charge.
2. Supabase creates the profile and a server-timestamped entitlement ending 14
   days later.
3. The authenticated router sends new users to `/welcome`.
4. The welcome screen shows both plans, the exact end date, a live countdown,
   Plus features, and `Continue with my free trial`.
5. The Profile screen exposes the current plan, plan selection, and purchase
   restoration.
6. When Plus expires, records remain readable. PostgreSQL prevents writes over
   Base limits and prevents recurring automation; contextual prompts direct
   users to `/pricing` before those requests occur.

## System architecture

```text
App Store / Google Play / Stripe web
                 |
                 v
             RevenueCat
       (pawpal_plus entitlement)
          |                |
          | SDK            | signed webhook secret
          v                v
      Flutter app   Supabase Edge Function
          |                |
          +-------> account_entitlements
                         |
                         v
              PostgreSQL RLS feature limits
```

- The Supabase Auth UUID is the RevenueCat `appUserID` on every platform.
- RevenueCat validates store receipts and unifies Apple, Google, and Stripe
  purchases under the `pawpal_plus` entitlement.
- `account_entitlements` is readable by its owner but cannot be mutated by an
  app client.
- The RevenueCat webhook uses the Supabase service role, a separate bearer
  secret, and HMAC verification over the raw request body. Each successfully
  processed event is stored in `subscription_events`; the event ID makes
  webhook retries idempotent.
- The app may unlock immediately from RevenueCat `CustomerInfo`, while the
  webhook asynchronously updates Supabase. PostgreSQL remains authoritative
  for server-enforced feature limits.
- `APP_ENABLE_BILLING=false` disables checkout while the Base/trial entitlement
  rules continue to operate. Do not enable checkout until sandbox products and
  webhook processing are verified.

## Catalog identifiers

Use these identifiers exactly in all systems:

| Item | Identifier |
|---|---|
| RevenueCat entitlement | `pawpal_plus` |
| RevenueCat offering | `default` |
| Monthly product | `pawpal_plus_monthly` |
| Annual product | `pawpal_plus_annual` |

The RevenueCat `default` offering must contain monthly and annual packages
linked to the corresponding platform products. Store-localized price strings
replace the fallback US prices in the interface after offerings load.

## Provider setup

### Apple

1. Enroll Creative Currents LLC in the App Store Small Business Program if
   eligible.
2. Create one subscription group named `PawPal Plus`.
3. Create the monthly and annual products using the identifiers above.
4. Set US prices to $4.99 and $29.99. Configure localized prices deliberately.
5. Do not attach an App Store introductory free trial.
6. Add the products to RevenueCat and attach them to `pawpal_plus`.
7. Verify purchase, cancellation, billing retry, restore, and account deletion
   in StoreKit sandbox/TestFlight.

### Google Play

1. Create matching monthly and annual subscription products/base plans.
2. Do not attach a Play introductory free trial.
3. Import and attach the products in RevenueCat.
4. Enable an appropriate account hold and grace period.
5. Verify purchase, pending payment, cancellation, resubscription, and restore
   with license testers.

### Stripe web

1. The live Stripe account `acct_1RgaKJKsWce5LjJW` is connected to the
   RevenueCat Billing app `app0207359e17`.
2. The RevenueCat Billing products `prodf487174619` (monthly) and
   `prod46e7146015` (annual) are mapped to the same `pawpal_plus` entitlement
   and to the monthly/annual packages in the `default` offering.
3. Pass the authenticated Supabase UUID as the RevenueCat app user ID. Never
   accept a client-provided user ID in a privileged Stripe endpoint without
   verifying the Supabase JWT.
4. Use Stripe Checkout and Customer Portal. Do not collect raw card data in
   PawPal.
5. Decide before launch whether Creative Currents is the merchant of record or
   whether Stripe Managed Payments will be used where eligible.
6. Keep in-app web-purchase links disabled initially. Native mobile purchases
   avoid region-specific Apple and Google link rules.

No public web purchase link has been created yet. RevenueCat requires a live
Terms & Conditions URL, and `https://creativecurrents.io/terms` currently shows
an under-construction page. Create and test the purchase link only after the
Terms, Privacy, subscription terms, and support pages are live.

## Supabase deployment

Apply the database migration:

```sh
supabase db push
```

Set the webhook secret and deploy the function:

```sh
supabase secrets set \
  REVENUECAT_WEBHOOK_SECRET=<generated-random-bearer-secret> \
  REVENUECAT_WEBHOOK_SIGNING_SECRET=<revenuecat-hmac-signing-secret>
supabase functions deploy revenuecat-webhook --no-verify-jwt
```

Configure RevenueCat to send webhooks to:

```text
https://<project-ref>.supabase.co/functions/v1/revenuecat-webhook
```

Set its Authorization header to `Bearer <the bearer secret>`, enable RevenueCat
HMAC webhook signing, and store the one-time signing secret in the Edge Function
secret shown above.

Configure the public SDK keys locally and in deployment environments:

```dotenv
APP_ENABLE_BILLING=true
REVENUECAT_IOS_API_KEY=appl_...
REVENUECAT_ANDROID_API_KEY=goog_...
REVENUECAT_WEB_API_KEY=rcb_...
```

RevenueCat public SDK keys may be shipped to clients. Stripe secret keys,
Supabase service-role keys, and webhook secrets must never be placed in the
Flutter `.env` asset.

## Production checklist

- [x] Migration 011 applied in the linked Supabase project
- [ ] Apple and Google products approved and imported into RevenueCat
- [x] Stripe connected and monthly/annual RevenueCat Billing products created
- [ ] Stripe Customer Portal and public web purchase link configured
- [x] RevenueCat entitlement/offering mappings verified for Test Store and web
- [x] Webhook bearer and HMAC secrets configured and endpoint verified
- [ ] Duplicate webhook delivery tested end to end
- [ ] Restore purchases tested on Apple and Google
- [ ] Cancellation and expired-access behavior tested
- [ ] Base limits tested directly against PostgreSQL RLS
- [ ] Terms, privacy, subscription terms, and support URLs are live
- [ ] Account deletion cancels or clearly directs cancellation of active plans
- [ ] Billing analytics and support runbook are ready
- [ ] Backup and recovery launch gate in `BACKUP_RECOVERY.md` is satisfied
- [ ] `APP_ENABLE_BILLING=true` only after all preceding checks pass

## Events to measure

At minimum, record these product events without health-record contents:

- pricing viewed and source
- trial started, trial days remaining, and trial expired
- monthly/annual plan selected
- purchase succeeded, failed, or canceled
- restore attempted and restored
- Base limit encountered by feature
- renewal, cancellation, billing issue, expiration, and refund

Never send pet medical notes, medication names, uploaded documents, or passport
contents to marketing analytics.
