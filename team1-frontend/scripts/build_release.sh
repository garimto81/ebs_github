#!/usr/bin/env bash
# Phase 5 — Production web build with obfuscation, split-debug-info, and
# bundle-size gatekeeper with 1-cycle self-correction.
#
# Usage:
#   bash scripts/build_release.sh [production.json]

set -euo pipefail

ENV_FILE="${1:-production.json}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "[build] $ENV_FILE not found — falling back to production.example.json"
  ENV_FILE="production.example.json"
fi

VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
DEBUG_INFO_DIR="build/app/outputs/symbols"   # Phase 5 spec path
OUTPUT_DIR="build/web"
MAX_KB="${BUNDLE_MAX_KB:-5120}"   # 5 MB per Phase 5 spec

mkdir -p "$DEBUG_INFO_DIR"

# -----------------------------------------------------------------------------
# Codegen prerequisite
# -----------------------------------------------------------------------------
echo "[build] dart run build_runner build --delete-conflicting-outputs"
dart run build_runner build --delete-conflicting-outputs

# -----------------------------------------------------------------------------
# Build (1st pass)
# -----------------------------------------------------------------------------
build_web() {
  flutter build web \
    --release \
    --web-renderer=html \
    --tree-shake-icons \
    --dart-define-from-file="$ENV_FILE" \
    --obfuscate \
    --split-debug-info="$DEBUG_INFO_DIR" \
    --source-maps \
    --output="$OUTPUT_DIR"
}

bundle_size_kb() {
  du -sk "$OUTPUT_DIR/main.dart.js" 2>/dev/null | cut -f1
}

echo "[build] pass-1: building web release…"
build_web
SIZE1=$(bundle_size_kb)
echo "[build] pass-1 main.dart.js = ${SIZE1} KB (limit ${MAX_KB} KB)"

# -----------------------------------------------------------------------------
# Gatekeeper + 1-cycle self-correction
# -----------------------------------------------------------------------------
if (( SIZE1 > MAX_KB )); then
  echo "[gatekeeper] OVERSIZE detected → entering self-correction loop"

  # Diagnostic 1: dependency tree dump
  dart pub deps --json > build/deps.json
  echo "[gatekeeper] dependency tree → build/deps.json"

  # Diagnostic 2: top-N bundle contributors via source map (if dart-sdk-tools)
  if command -v source-map-explorer >/dev/null 2>&1; then
    source-map-explorer "$OUTPUT_DIR/main.dart.js" \
      --html "$OUTPUT_DIR/bundle-report.html" || true
    echo "[gatekeeper] bundle report → $OUTPUT_DIR/bundle-report.html"
  fi

  # Heuristic mitigation: ensure --tree-shake-icons + --dart2js-optimization
  echo "[gatekeeper] pass-2: re-building with --dart2js-optimization=O4"
  flutter build web \
    --release \
    --web-renderer=html \
    --tree-shake-icons \
    --dart2js-optimization=O4 \
    --dart-define-from-file="$ENV_FILE" \
    --obfuscate \
    --split-debug-info="$DEBUG_INFO_DIR" \
    --source-maps \
    --output="$OUTPUT_DIR"

  SIZE2=$(bundle_size_kb)
  echo "[build] pass-2 main.dart.js = ${SIZE2} KB"

  if (( SIZE2 > MAX_KB )); then
    echo "[gatekeeper: FAILED] bundle still oversized after self-correction."
    echo "  Manual review required. Inspect:"
    echo "    - build/deps.json"
    echo "    - $OUTPUT_DIR/bundle-report.html"
    exit 1
  fi
  FINAL_KB=$SIZE2
else
  FINAL_KB=$SIZE1
fi

echo ""
echo "[gatekeeper: PASSED] main.dart.js = ${FINAL_KB} KB"
echo "[build] artefacts:"
echo "  - $OUTPUT_DIR/                 (deployable)"
echo "  - $DEBUG_INFO_DIR/             (Sentry sourcemap upload target)"
