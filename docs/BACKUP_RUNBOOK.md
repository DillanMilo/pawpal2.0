# PawPal Backup Runbook

This runbook turns the recovery design into an executable database and Storage
backup. It is intentionally disabled until a separate destination and the
required credentials are configured.

## Verified hosted status (2026-07-27)

- Project: `Pawpal`, production branch `main`
- Organization plan: Free
- Supabase scheduled backups: unavailable on Free
- PITR: unavailable; the dashboard identifies it as a Pro add-on starting at
  $100/month
- Storage buckets present: `profile-photos`, `pet-photos`,
  `medical-documents`, and `activity-photos`
- Supabase Storage S3 protocol: enabled; source access keys still pending
- Independent provider decision: Cloudflare R2 Standard
- Supabase plan decision: remain on Free for now; no hosted daily backup or PITR
- R2 subscription: active
- R2 bucket: `pawpal-production-backups`, private, Standard storage
- R2 retention: 90-day bucket lock and deletion after 180 days
- R2 destination credential: Object Read & Write, bucket-scoped, stored in
  GitHub Actions secrets

PawPal therefore has no hosted database recovery point today. Upgrading to Pro
would add up to seven days of daily backups, but would still not back up the
Storage objects themselves.

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

- `scripts/backup/pawpal_backup.sh` creates a PostgreSQL custom-format dump,
  copies all four Storage buckets through Supabase's server-only S3 endpoint,
  records SHA-256 checksums, encrypts the combined payload with AES-256 and
  PBKDF2, and uploads it to a separate S3-compatible destination.
- `scripts/backup/verify_backup.sh` decrypts an archive, checks every payload
  checksum, validates the PostgreSQL archive catalog, and confirms all four
  bucket directories exist.
- `.github/workflows/backup.yml` is scheduled nightly at 06:17 UTC. Scheduled
  runs remain skipped until the repository variable
  `PAWPAL_BACKUPS_ENABLED=true` is set. Manual runs remain available for setup.

## Configuration checklist

1. Upgrade the production Supabase organization to Pro if the budget allows.
   Do not enable PITR unless the lower RPO justifies its separate cost.
2. [Complete] The private `pawpal-production-backups` R2 bucket is active in a
   different account/security boundary, with a 90-day bucket lock and a
   180-day lifecycle.
3. In Supabase Storage > S3, enable the protocol and generate a server-only
   access key. These credentials bypass RLS and must never ship in the app.
4. Create a read-oriented database credential suitable for `pg_dump`. Confirm
   it can read all required schemas, including `auth` and `storage` metadata.
5. The five R2 destination values are in GitHub Actions secrets. Add the five
   Supabase source values plus `PAWPAL_BACKUP_ENCRYPTION_PASSPHRASE`; keep the
   passphrase in an independent password manager.
6. Run the workflow manually. Download the encrypted object from the backup
   account and run `verify_backup.sh` locally.
7. Set the repository variable `PAWPAL_BACKUPS_ENABLED=true` only after the
   manual run succeeds. Configure GitHub Actions failure notifications for the
   recovery owner.

## Recovery drill still required

Archive verification is not a restore drill. Restore the database into an
isolated non-production project, upload sample objects from every bucket,
compare row counts, validate RLS and signed document access, and record the
achieved RPO/RTO. Never point RevenueCat, Stripe, email, or notification
webhooks from the recovery project at production providers.
