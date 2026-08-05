#!/bin/sh

set -eu

artifact="${1:?Usage: verify_ios_release_artifact.sh <Runner.app|archive.xcarchive>}"
expected_supabase_url="https://esrxaniydzgzxxxwzqca.supabase.co"

if [ ! -d "$artifact" ]; then
  echo "error: iOS release artifact not found: $artifact" >&2
  exit 1
fi

case "$artifact" in
  *.xcarchive)
    app=$(find "$artifact/Products/Applications" -maxdepth 1 -type d -name '*.app' -print | head -n 1)
    ;;
  *.app)
    app="$artifact"
    ;;
  *)
    echo "error: Expected a .app bundle or .xcarchive: $artifact" >&2
    exit 1
    ;;
esac

if [ -z "${app:-}" ] || [ ! -d "$app" ]; then
  echo "error: Runner app bundle is missing from: $artifact" >&2
  exit 1
fi

env_file=$(find "$app" -type f -path '*/flutter_assets/.env' -print | head -n 1)
if [ -z "$env_file" ] || [ ! -f "$env_file" ]; then
  echo "error: Bundled Flutter environment file is missing." >&2
  exit 1
fi

supabase_url=$(sed -n 's/^SUPABASE_URL=//p' "$env_file" | tail -n 1)
supabase_anon_key=$(sed -n 's/^SUPABASE_ANON_KEY=//p' "$env_file" | tail -n 1)

if [ "$supabase_url" != "$expected_supabase_url" ]; then
  echo "error: Bundled SUPABASE_URL is not the PawPal production project." >&2
  exit 1
fi

if [ ${#supabase_anon_key} -lt 20 ] || [ "$supabase_anon_key" = "your_supabase_anon_key" ]; then
  echo "error: Bundled SUPABASE_ANON_KEY is missing or a placeholder." >&2
  exit 1
fi

if grep -R -a -q 'test\.supabase\.co' "$app"; then
  echo "error: Release artifact still contains the retired test Supabase hostname." >&2
  exit 1
fi

version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Info.plist")
build=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$app/Info.plist")
echo "Verified PawPal iOS $version ($build): production backend only."
