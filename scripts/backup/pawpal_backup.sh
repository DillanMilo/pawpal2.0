#!/usr/bin/env bash
set -Eeuo pipefail

readonly PAWPAL_BUCKETS=(
  profile-photos
  pet-photos
  medical-documents
  activity-photos
)

require_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: $name" >&2
    exit 1
  fi
}

for name in \
  PAWPAL_DATABASE_URL \
  PAWPAL_SOURCE_S3_ENDPOINT \
  PAWPAL_SOURCE_S3_REGION \
  PAWPAL_SOURCE_S3_ACCESS_KEY_ID \
  PAWPAL_SOURCE_S3_SECRET_ACCESS_KEY \
  PAWPAL_BACKUP_S3_URI \
  PAWPAL_BACKUP_S3_REGION \
  PAWPAL_BACKUP_S3_ACCESS_KEY_ID \
  PAWPAL_BACKUP_S3_SECRET_ACCESS_KEY \
  PAWPAL_BACKUP_ENCRYPTION_PASSPHRASE; do
  require_var "$name"
done

for command_name in pg_dump aws openssl tar; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command is not installed: $command_name" >&2
    exit 1
  fi
done

checksum() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

readonly backup_started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
readonly backup_id="$(date -u +%Y%m%dT%H%M%SZ)"
readonly working_dir="$(mktemp -d "${TMPDIR:-/tmp}/pawpal-backup.XXXXXX")"
readonly payload_dir="$working_dir/payload"
readonly encrypted_archive="$working_dir/pawpal-backup-$backup_id.tar.gz.enc"

cleanup() {
  rm -rf -- "$working_dir"
}
trap cleanup EXIT

mkdir -p "$payload_dir/database" "$payload_dir/storage"

echo "Creating PawPal database dump..."
pg_dump \
  --dbname="$PAWPAL_DATABASE_URL" \
  --format=custom \
  --no-owner \
  --no-acl \
  --file="$payload_dir/database/pawpal.pgdump"

echo "Copying PawPal Storage buckets..."
for bucket in "${PAWPAL_BUCKETS[@]}"; do
  mkdir -p "$payload_dir/storage/$bucket"
  AWS_ACCESS_KEY_ID="$PAWPAL_SOURCE_S3_ACCESS_KEY_ID" \
  AWS_SECRET_ACCESS_KEY="$PAWPAL_SOURCE_S3_SECRET_ACCESS_KEY" \
  AWS_DEFAULT_REGION="$PAWPAL_SOURCE_S3_REGION" \
    aws s3 sync \
      "s3://$bucket" \
      "$payload_dir/storage/$bucket" \
      --endpoint-url "$PAWPAL_SOURCE_S3_ENDPOINT" \
      --only-show-errors
done

{
  echo "backup_id=$backup_id"
  echo "started_at=$backup_started_at"
  echo "completed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "database_format=postgres_custom"
  echo "storage_buckets=${PAWPAL_BUCKETS[*]}"
} > "$payload_dir/backup-metadata.txt"

while IFS= read -r -d '' path; do
  relative_path="${path#"$payload_dir/"}"
  printf '%s  %s\n' "$(checksum "$path")" "$relative_path"
done < <(find "$payload_dir/database" "$payload_dir/storage" -type f -print0 | sort -z) \
  > "$payload_dir/SHA256SUMS"

echo "Encrypting backup archive..."
tar -C "$payload_dir" -czf - . | openssl enc \
  -aes-256-cbc \
  -salt \
  -pbkdf2 \
  -iter 200000 \
  -pass env:PAWPAL_BACKUP_ENCRYPTION_PASSPHRASE \
  -out "$encrypted_archive"

archive_checksum="$(checksum "$encrypted_archive")"
printf '%s  %s\n' "$archive_checksum" "$(basename "$encrypted_archive")" \
  > "$encrypted_archive.sha256"

destination="${PAWPAL_BACKUP_S3_URI%/}/$backup_id"
destination_args=()
if [[ -n "${PAWPAL_BACKUP_S3_ENDPOINT:-}" ]]; then
  destination_args+=(--endpoint-url "$PAWPAL_BACKUP_S3_ENDPOINT")
fi

echo "Uploading encrypted backup to the independent destination..."
AWS_ACCESS_KEY_ID="$PAWPAL_BACKUP_S3_ACCESS_KEY_ID" \
AWS_SECRET_ACCESS_KEY="$PAWPAL_BACKUP_S3_SECRET_ACCESS_KEY" \
AWS_DEFAULT_REGION="$PAWPAL_BACKUP_S3_REGION" \
  aws s3 cp "$encrypted_archive" "$destination/$(basename "$encrypted_archive")" \
    "${destination_args[@]}" --only-show-errors

AWS_ACCESS_KEY_ID="$PAWPAL_BACKUP_S3_ACCESS_KEY_ID" \
AWS_SECRET_ACCESS_KEY="$PAWPAL_BACKUP_S3_SECRET_ACCESS_KEY" \
AWS_DEFAULT_REGION="$PAWPAL_BACKUP_S3_REGION" \
  aws s3 cp "$encrypted_archive.sha256" \
    "$destination/$(basename "$encrypted_archive.sha256")" \
    "${destination_args[@]}" --only-show-errors

echo "Backup uploaded successfully: $destination"
