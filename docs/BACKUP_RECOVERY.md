# PawPal Backup and Recovery

> Current status: **independent nightly backup and automated restore verified
> July 28, 2026**.

PawPal remains on Supabase Free without hosted Point-in-Time Recovery. Its
independent recovery path uses encrypted, Supabase-compatible logical exports
and copies of all four Storage buckets in a separately controlled Cloudflare
R2 bucket.

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

The independent encrypted database-and-Storage job is implemented in
`scripts/backup/`, with the setup and recovery procedure in
`BACKUP_RUNBOOK.md`. Manual run `30404333546` restored backup
`20260728T222318Z` into an isolated local Supabase stack and recovered all four
Storage bucket trees. Nightly backups are enabled.

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
- [x] Create the selected Cloudflare R2 destination
- [x] Create least-privilege credentials for database dumps and Storage reads
- [x] Configure encrypted logical database exports to the separate destination
- [x] Configure copying/versioning for all four Storage buckets
- [x] Set retention and deletion protection on the backup destination
- [ ] Alert when either database or Storage backup jobs fail
- [x] Restore the database into an isolated non-production Supabase stack
- [x] Restore objects from every Storage bucket and verify checksums
- [x] Record the automated recovery time and any failed steps
      (2 minutes 1 second; no failed steps in verified run `30404333546`)

The automated restore path is verified. Continue quarterly hands-on recovery
drills for RLS, signed URLs, and an end-to-end sample account.

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
