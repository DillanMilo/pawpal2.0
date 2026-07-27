#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: PAWPAL_BACKUP_ENCRYPTION_PASSPHRASE=... $0 BACKUP.tar.gz.enc" >&2
  exit 1
fi
if [[ -z "${PAWPAL_BACKUP_ENCRYPTION_PASSPHRASE:-}" ]]; then
  echo "Missing PAWPAL_BACKUP_ENCRYPTION_PASSPHRASE" >&2
  exit 1
fi
for command_name in openssl tar pg_restore; do
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

readonly archive_path="$1"
readonly working_dir="$(mktemp -d "${TMPDIR:-/tmp}/pawpal-verify.XXXXXX")"
cleanup() {
  rm -rf -- "$working_dir"
}
trap cleanup EXIT

openssl enc -d \
  -aes-256-cbc \
  -pbkdf2 \
  -iter 200000 \
  -pass env:PAWPAL_BACKUP_ENCRYPTION_PASSPHRASE \
  -in "$archive_path" | tar -C "$working_dir" -xzf -

while read -r expected relative_path; do
  relative_path="${relative_path#\*}"
  if [[ ! -f "$working_dir/$relative_path" ]]; then
    echo "Missing backup payload: $relative_path" >&2
    exit 1
  fi
  actual="$(checksum "$working_dir/$relative_path")"
  if [[ "$actual" != "$expected" ]]; then
    echo "Checksum mismatch: $relative_path" >&2
    exit 1
  fi
done < "$working_dir/SHA256SUMS"

pg_restore --list "$working_dir/database/pawpal.pgdump" >/dev/null

for bucket in profile-photos pet-photos medical-documents activity-photos; do
  if [[ ! -d "$working_dir/storage/$bucket" ]]; then
    echo "Missing Storage bucket directory: $bucket" >&2
    exit 1
  fi
done

echo "Backup archive is decryptable and all payload checksums are valid."
echo "A staging database restore and sample object reads are still required."
