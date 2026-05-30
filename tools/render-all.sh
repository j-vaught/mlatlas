#!/usr/bin/env bash
# Compile every example to PDF + PNG. Local, manual verification (no CI).
#   TYPST=/path/to/typst ./tools/render-all.sh
set -euo pipefail
cd "$(dirname "$0")/.."
TYPST="${TYPST:-typst}"
mkdir -p build/png
fail=0
for f in examples/*.typ; do
  name="$(basename "$f" .typ)"
  if "$TYPST" compile --root . "$f" "build/$name.pdf" 2>"build/$name.log"; then
    pdftoppm -png -r 150 "build/$name.pdf" "build/png/$name" >/dev/null 2>&1 || true
    echo "ok   $name"
  else
    echo "FAIL $name"
    grep -v deprecated "build/$name.log" | head -6
    fail=1
  fi
done
exit $fail
