# PawPal Backup Runbook

This runbook documents PawPal's executable, independently hosted database and
Storage backup. The encrypted backup and isolated restore drill were verified
on July 28, 2026, and nightly runs are enabled.

## Verified hosted status (2026-07-28)

- Project: `Pawpal`, production branch `main`
- Organization plan: Free
- Supabase scheduled backups: unavailable on Free
- PITR: unavailable; the dashboard identifies it as a Pro add-on starting at
  $100/month
- Storage buckets present: `profile-photos`, `pet-photos`,
  `medical-documents`, and `activity-photos`
- Supabase Storage S3 protocol: enabled with a rotated server-only access key
- Independent provider decision: Cloudflare R2 Standard
- Supabase plan decision: remain on Free for now; no hosted daily backup or PITR
- R2 subscription: active
- R2 bucket: `pawpal-production-backups`, private, Standard storage
- R2 retention: 90-day bucket lock and deletion after 180 days
- R2 destination credential: Object Read & Write, bucket-scoped, stored in
  GitHub Actions secrets
- Database backup role: `pawpal_backup`, read-only by default, with
  `pg_read_all_data` and RLS bypass solely so managed `auth` data can be dumped
- Nightly workflow: enabled with `PAWPAL_BACKUPS_ENABLED=true`

PawPal has an independent nightly encrypted recovery point in R2, but no
Supabase-hosted recovery point. Upgrading to Pro would add up to seven days of
hosted daily backups, but would still not back up the Storage objects
themselves.

## Destination decision: Cloudflare R2

Use Cloudflare R2 Standard rather than AWS S3 for PawPal's independent copy.
R2 is S3-compatible, has no egress charge, includes 10 GB-month of Standard
storage per month, and supports bucket locks. This keeps early backup cost low
without making recovery downloads expensive.

Create the destination with these settings:

- Bucket: `pawpal-production-backups`
- Storage class: Standard
- S3 region: `auto`
- S3 endpoint:
  `https://c1bfa42998fb4d838007cdf476bbf92e.r2.cloudflarestorage.com`
- Bucket lock: retain every object for 90 days
- Lifecycle: delete objects after 180 days
- API token: Object Read & Write, scoped only to this bucket

The R2 destination is active and its five destination settings are stored as
GitHub Actions secrets. The generated secret was cleared after the encrypted
GitHub handoff and was never written to the repository or app.

## What is implemented

- `scripts/backup/pawpal_backup.sh` creates Supabase-compatible
  `roles.sql`, `schema.sql`, and `data.sql` exports; copies all four Storage
  buckets through Supabase's server-only S3 endpoint; records SHA-256
  checksums; encrypts the combined payload with AES-256 and PBKDF2; and uploads
  it to a separate S3-compatible destination.
- `scripts/backup/verify_backup.sh` decrypts an archive, checks every payload
  checksum, validates the three SQL exports, and confirms all four bucket
  directories exist.
- `.github/workflows/backup.yml` is scheduled nightly at 06:17 UTC. Scheduled
  runs are enabled by `PAWPAL_BACKUPS_ENABLED=true`. Manual runs also execute
  the complete isolated restore drill.

## Configuration checklist

1. [Optional] Upgrade the production Supabase organization to Pro if the budget allows.
   Do not enable PITR unless the lower RPO justifies its separate cost.
2. [Complete] The private `pawpal-production-backups` R2 bucket is active in a
   different account/security boundary, with a 90-day bucket lock and a
   180-day lifecycle.
3. [Complete] The Supabase Storage S3 protocol and rotated server-only source
   access key are active. These credentials bypass RLS and must never ship in
   the app.
4. [Complete] The dedicated `pawpal_backup` database credential can read the
   required application, `auth`, and `storage` data without write privileges.
5. [Complete] All source, destination, and encryption values are stored as
   encrypted GitHub Actions secrets. The database password and encryption
   passphrase are also stored independently in the Mac login Keychain.
6. [Complete] Manual workflow run `30404333546` created backup
   `20260728T222318Z`, verified the encrypted archive, restored the database,
   and recovered all four Storage bucket trees.
7. [Complete] `PAWPAL_BACKUPS_ENABLED=true` enables nightly runs. Configure
   GitHub Actions failure notifications for the recovery owner.

The workflow performs a names-only preflight before installing tools. Missing
secret values are never printed.

## Verified recovery drill

Manual workflow run `30404333546` completed the automated restore drill in
2 minutes 1 second. It decrypted and checksum-verified the archive, started an
isolated local Supabase stack, restored 10 public tables and 2 auth users, and
recovered checksum-verified copies of all four Storage bucket trees. The stack
was stopped after verification.

Quarterly hands-on drills should additionally validate RLS, signed medical
document access, and a complete sample user journey. Never point RevenueCat,
Stripe, email, or notification webhooks from a recovery environment at
production providers.
