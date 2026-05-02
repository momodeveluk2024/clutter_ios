#!/usr/bin/env sh
set -eu

DATABASE_URL="${DATABASE_URL:-${1:-}}"
OUTPUT_DIR="${OUTPUT_DIR:-backups}"

if [ -z "$DATABASE_URL" ]; then
  echo "DATABASE_URL or first argument is required." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
OUTPUT_PATH="$OUTPUT_DIR/nutrivita-$TIMESTAMP.dump"

pg_dump --format=custom --no-owner --no-acl --file "$OUTPUT_PATH" "$DATABASE_URL"
echo "Backup written to $OUTPUT_PATH"
