#!/usr/bin/env bash
# Phase 5 — Sentry release tagging + sourcemap upload.
#
# Phase 3 C9 연계: SentryLoggerStub 활성화 시 Sentry SDK 로 release 매핑이
# 가능해야 sourcemap 이 stack trace 를 demangle 한다.
#
# 2026-04-28 (P1 redesign) — Web vs Native scope:
#   WEB  primary path: dart2js .js.map sourcemap upload (build/web/) — 본 스크립트 메인
#   NATIVE legacy path: --split-debug-info 산출물 (build/debug-info/<version>/) — web 미지원,
#                      향후 mobile target 추가 시 활성화. 현재는 디렉토리 부재 → 자동 skip.
#
#   Flutter web build 는 `--obfuscate` / `--split-debug-info` 미지원이므로
#   Dockerfile 에서 두 flag 제거됨. .js.map 만으로 Sentry sourcemap demangle 가능.
#
# 환경변수:
#   SENTRY_AUTH_TOKEN   필수 (없으면 STUB MODE 로 dry-run)
#   SENTRY_ORG          기본 ebs
#   SENTRY_PROJECT      기본 lobby-web
#   SENTRY_RELEASE      기본 ebs-lobby@<pubspec version>+phase5
#   SENTRY_ENVIRONMENT  기본 production
#   SENTRY_URL_PREFIX   기본 ~/  (CDN 경로 변경 시 override)

set -euo pipefail

VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
RELEASE="${SENTRY_RELEASE:-ebs-lobby@${VERSION}+phase5}"
ENV="${SENTRY_ENVIRONMENT:-production}"
ORG="${SENTRY_ORG:-ebs}"
PROJECT="${SENTRY_PROJECT:-lobby-web}"
URL_PREFIX="${SENTRY_URL_PREFIX:-~/}"
DEBUG_INFO_DIR="build/debug-info/${VERSION}"

# Web build 산출물 가드 — sourcemap 의 1차 전제
if [[ ! -d "build/web" ]]; then
  echo "[sentry] build/web 부재 — Flutter web build 먼저 실행 필요." >&2
  echo "  hint: flutter build web --release --source-maps --output=build/web" >&2
  exit 2
fi
if [[ ! -f "build/web/main.dart.js.map" ]] && ! ls build/web/*.js.map >/dev/null 2>&1; then
  echo "[sentry] build/web/*.js.map 부재 — --source-maps 누락 의심." >&2
  echo "  Flutter build 명령에 --source-maps 가 포함되어 있는지 확인." >&2
  exit 2
fi

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

# ── PRIMARY: Web sourcemap upload ─────────────────────────────────────────
# dart2js 산출물 = build/web/main.dart.js + main.dart.js.map (+ defer chunk *.js.map)
# sentry-cli 가 디렉토리 안의 .js / .map 쌍을 자동 매칭하여 release 에 attach.
sentry-cli sourcemaps upload \
  --org="$ORG" --project="$PROJECT" \
  --release="$RELEASE" \
  --url-prefix="$URL_PREFIX" \
  build/web

# ── LEGACY: Native split-debug-info ─────────────────────────────────────────
# Flutter web 은 --split-debug-info 미지원 → DEBUG_INFO_DIR 항상 부재.
# 향후 mobile target (android/ios) 추가 시 빌드 단계에서 채워지면 자동 활성.
# 부재 시 silent skip.
if [[ -d "$DEBUG_INFO_DIR" ]] && [[ -n "$(ls -A "$DEBUG_INFO_DIR" 2>/dev/null)" ]]; then
  echo "[sentry] native debug-info 발견 → upload (mobile target?)"
  sentry-cli debug-files upload \
    --org="$ORG" --project="$PROJECT" \
    "$DEBUG_INFO_DIR" || true
fi

sentry-cli releases finalize "$RELEASE" --org="$ORG"
sentry-cli releases deploys "$RELEASE" new \
  --org="$ORG" --env="$ENV"

echo "[sentry] release published ✅"
