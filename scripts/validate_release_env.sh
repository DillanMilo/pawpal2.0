#!/bin/sh

set -eu

if [ "${CONFIGURATION:-Release}" != "Release" ]; then
  exit 0
fi

env_file="${1:-$(dirname "$0")/../.env}"
expected_supabase_url="https://esrxaniydzgzxxxwzqca.supabase.co"

if [ ! -f "$env_file" ]; then
  echo "error: Release environment file not found: $env_file" >&2
  exit 1
fi

supabase_url=$(sed -n 's/^SUPABASE_URL=//p' "$env_file" | tail -n 1)
supabase_anon_key=$(sed -n 's/^SUPABASE_ANON_KEY=//p' "$env_file" | tail -n 1)

if [ "$supabase_url" != "$expected_supabase_url" ]; then
  echo "error: Refusing release build: SUPABASE_URL is not the PawPal production project." >&2
  exit 1
fi

if [ ${#supabase_anon_key} -lt 20 ] || [ "$supabase_anon_key" = "your_supabase_anon_key" ]; then
  echo "error: Refusing release build: SUPABASE_ANON_KEY is missing or a placeholder." >&2
  exit 1
fi

echo "Release environment verified for the PawPal production backend."
