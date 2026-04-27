#!/usr/bin/env bash
# Phase 5 — Sentry release tagging + sourcemap upload.
#
# Phase 3 C9 연계: SentryLoggerStub 활성화 시 Sentry SDK 로 release 매핑이
# 가능해야 sourcemap 이 stack trace 를 demangle 한다.
#
# 환경변수:
#   SENTRY_AUTH_TOKEN   필수
#   SENTRY_ORG          기본 ebs
#   SENTRY_PROJECT      기본 lobby-web
#   SENTRY_RELEASE      기본 ebs-lobby@<pubspec version>+phase5
#   SENTRY_ENVIRONMENT  기본 production

set -euo pipefail

VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
RELEASE="${SENTRY_RELEASE:-ebs-lobby@${VERSION}+phase5}"
ENV="${SENTRY_ENVIRONMENT:-production}"
ORG="${SENTRY_ORG:-ebs}"
PROJECT="${SENTRY_PROJECT:-lobby-web}"
DEBUG_INFO_DIR="build/debug-info/${VERSION}"

if ! command -v sentry-cli >/dev/null 2>&1; then
  echo "[sentry] sentry-cli not installed — STUB MODE."
  echo "[sentry] Would have:"
  echo "  - new release: $RELEASE"
  echo "  - upload sourcemaps: build/web (release=$RELEASE)"
  echo "  - upload debug-info: $DEBUG_INFO_DIR"
  echo "  - finalize + deploy ($ENV)"
  exit 0
fi

if [[ -z "${SENTRY_AUTH_TOKEN:-}" ]]; then
  echo "[sentry] SENTRY_AUTH_TOKEN missing — aborting."
  exit 1
fi

echo "[sentry] release: $RELEASE  env: $ENV  org: $ORG  project: $PROJECT"

sentry-cli releases new "$RELEASE" \
  --org="$ORG" --project="$PROJECT"

sentry-cli releases set-commits "$RELEASE" \
  --org="$ORG" --auto

# Web sourcemap upload (build/web/main.dart.js + build/web/main.dart.js.map)
sentry-cli sourcemaps upload \
  --org="$ORG" --project="$PROJECT" \
  --release="$RELEASE" \
  --url-prefix="~/" \
  build/web

# Native split-debug-info (향후 mobile target 추가 시 사용)
if [[ -d "$DEBUG_INFO_DIR" ]]; then
  sentry-cli debug-files upload \
    --org="$ORG" --project="$PROJECT" \
    "$DEBUG_INFO_DIR" || true
fi

sentry-cli releases finalize "$RELEASE" --org="$ORG"
sentry-cli releases deploys "$RELEASE" new \
  --org="$ORG" --env="$ENV"

echo "[sentry] release published ✅"
