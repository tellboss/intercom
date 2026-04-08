#!/bin/bash
set -e

cd "$(dirname "$0")"

NAME="intercom-server"
OUT="${NAME}.zip"

rm -f "$OUT"

zip -r "$OUT" \
  src/ \
  package.json \
  bun.lock \
  tsconfig.json \
  README.md \
  -x "*.DS_Store"

echo "Packed: $OUT ($(du -h "$OUT" | cut -f1))"
