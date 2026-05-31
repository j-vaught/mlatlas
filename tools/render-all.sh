#!/usr/bin/env bash
# Compile every example to PDF + PNG. Local, manual verification (no CI).
#   TYPST=/path/to/typst ./tools/render-all.sh
set -euo pipefail
cd "$(dirname "$0")/.."
TYPST="${TYPST:-typst}"
mkdir -p build/png
fail=0
for f in examples/*.typ examples/refs/*.typ; do
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

# Diagnostic verification pages (cam-sweep, before/after, theme/B&W). Opt-in so they stay out of
# the public example gallery:  RENDER_PROBES=1 ./tools/render-all.sh
if [ "${RENDER_PROBES:-0}" = "1" ] && [ -d probes ]; then
  for f in probes/*.typ; do
    name="probe-$(basename "$f" .typ)"
    if "$TYPST" compile --root . "$f" "build/$name.pdf" 2>"build/$name.log"; then
      pdftoppm -png -r 140 "build/$name.pdf" "build/png/$name" >/dev/null 2>&1 || true
      echo "ok   $name"
    else
      echo "FAIL $name"
      grep -v deprecated "build/$name.log" | head -6
      fail=1
    fi
  done
fi
exit $fail
