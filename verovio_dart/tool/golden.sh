#!/usr/bin/env bash
# Generates reference SVGs from the C++ Verovio binary for the whole corpus.
# Usage: ./tool/golden.sh [binary] [outdir]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${1:-$ROOT/../build/verovio}"
OUT="${2:-$ROOT/test/golden/cpp}"
RESOURCES="$ROOT/assets/data"
CORPUS="$ROOT/test/corpus"

mkdir -p "$OUT"
count=0
failed=0
while IFS= read -r mei; do
  rel="${mei#"$CORPUS"/}"
  svg="$OUT/${rel%.mei}.svg"
  mkdir -p "$(dirname "$svg")"
  if "$BIN" -r "$RESOURCES" -o "$svg" "$mei" > /dev/null 2>&1; then
    count=$((count + 1))
  else
    echo "FAILED: $rel" >&2
    rm -f "$svg"
    failed=$((failed + 1))
  fi
done < <(find "$CORPUS" -name '*.mei' | sort)

echo "Generated $count goldens ($failed failed) in $OUT"
