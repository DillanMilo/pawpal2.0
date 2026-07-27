# PawPal Backup and Recovery

> Current status: **not production-ready and not verified**.

The repository contains migrations and security policies, but it does not
contain evidence that database Point-in-Time Recovery, independent logical
backups, storage-object replication, or restore drills are configured for the
hosted Supabase project. Supabase CLI access in this workspace also cannot see
the configured project.

## Hosted audit — 2026-07-20

The production `Pawpal` project was audited in the Supabase dashboard:

- The organization is on the Free plan.
- Scheduled database backups are not available, so visible retention is zero.
- PITR is not enabled and requires both Pro and a separate add-on.
- The four expected Storage buckets exist.
- The Storage S3 protocol is enabled, but no server access keys exist yet.
- Cloudflare R2 Standard was selected for the independent destination; bucket
  creation is pending Cloudflare sign-in.
- Supabase will remain on Free for now, so hosted daily backups and PITR remain
  unavailable.

The independent encrypted database-and-Storage job is scaffolded in
`scripts/backup/`, with the setup and recovery procedure in
`BACKUP_RUNBOOK.md`. It remains deliberately disabled until a separate backup
destination and credentials are configured.

## Important Supabase boundary

Supabase database backups cover PostgreSQL data and Storage metadata. They do
not restore the actual objects uploaded through Supabase Storage. PawPal must
therefore protect two different systems:

1. PostgreSQL: accounts, pet profiles, records, reminders, activities, and
   subscription entitlements.
2. Storage objects: profile images, pet images, medical documents, and activity
   photos.

## Required production design

| Layer | Minimum | Preferred once revenue begins |
|---|---|---|
| Database | Supabase daily backups | PITR with documented retention |
| Independent DB copy | Encrypted weekly logical dump outside Supabase | Encrypted daily dump with lifecycle retention |
| Storage | Nightly copy to a separate private bucket/account | Versioned cross-account replication |
| Restore testing | Quarterly staging restore | Monthly automated integrity check plus quarterly drill |
| Recovery targets | RPO 24h, documented RTO | RPO 1h or better, RTO under 4h |

Backups should live in a separate cloud account or security boundary so a
mistake or compromised Supabase credential cannot delete the production data
and its backup together.

## Launch gate

- [x] Confirm the production Supabase plan and visible daily backup retention
      (Free plan; no scheduled backups or retention)
- [x] Decide whether daily recovery is sufficient or enable PITR
      (remain on Free for now; use the independent R2 job instead)
- [ ] Create the selected Cloudflare R2 destination
- [ ] Create least-privilege credentials for database dumps and Storage reads
- [ ] Configure encrypted logical database exports to the separate destination
- [ ] Configure copying/versioning for all four Storage buckets
- [ ] Set retention and deletion protection on the backup destination
- [ ] Alert when either database or Storage backup jobs fail
- [ ] Restore the database into a non-production Supabase project
- [ ] Restore sample objects from every Storage bucket and verify checksums
- [ ] Record the recovery owner, recovery time, and any failed steps

Do not describe PawPal data as “backed up” to customers until both the database
and object-storage restore tests have succeeded.

## User-facing resilience

Platform backups are not a substitute for portability. Before enforcing paid
limits broadly, add a user export containing pet profiles, appointments,
reminders, activities, medical metadata, and original uploaded documents. A
downgraded user must retain read, export, and delete access to their existing
information.

## Recovery drill

1. Declare a staging-only recovery exercise and record its start time.
2. Restore the chosen database recovery point to an isolated project.
3. Restore object copies into isolated private buckets.
4. Validate row counts, foreign keys, RLS, signed medical-document access, and
   a sample account end to end.
5. Confirm subscription events are not replayed against production providers.
6. Record achieved RPO/RTO and remediate every manual or failed step.
7. Delete the isolated recovery environment securely after the exercise.
