#!/usr/bin/env bash
# EBS Lobby web 빌드 + Docker 재배포 자동화 (2026-05-07 v2).
#
# 효과:
# - BUILD_ID 자동 주입 (YYYYMMDD-HHMM) → Dockerfile ARG → Flutter --dart-define
# - docker compose build (Dockerfile builder stage 가 자체 flutter build 수행)
# - docker compose up + healthcheck 대기 (60s)
# - login footer + lobby sidebar footer 양쪽에 BUILD_ID 표시 = 빌드 식별 즉시 확인
#
# 사용법:
#   bash tools/build_lobby.sh                # 자동 BUILD_ID + 재빌드 + 재배포
#   bash tools/build_lobby.sh --no-cache     # 강제 풀 빌드 (SDK download 재실행)
#   bash tools/build_lobby.sh --dry-run      # 명령만 출력
#
# 종료 코드:
#   0  성공 (lobby-web healthy)
#   2  docker build/up 실패
#   3  healthcheck timeout
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

export BUILD_ID="$(date +%Y%m%d-%H%M)"
NO_CACHE=""
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --no-cache)  NO_CACHE="--no-cache" ;;
    --dry-run)   DRY_RUN=1 ;;
    --help|-h)
      sed -n '2,16p' "$0"
      exit 0
      ;;
  esac
done

run() {
  echo "+ $*"
  if [ $DRY_RUN -eq 0 ]; then eval "$@"; fi
}

echo "════════════════════════════════════════════════════════════"
echo " EBS Lobby Build · BUILD_ID=$BUILD_ID"
echo "════════════════════════════════════════════════════════════"

# Dockerfile builder stage 가 flutter build web 자체 수행 (cirruslabs:3.41.9 SDK 포함).
# host 측 flutter SDK 불필요 — docker compose 가 build context (.) 와 args 로 BUILD_ID 전달.
echo ""
echo "[1/2] Docker lobby-web 이미지 재빌드 (BUILD_ID=$BUILD_ID)..."
run "BUILD_ID=$BUILD_ID docker compose --profile web build $NO_CACHE lobby-web"

echo ""
echo "[2/2] Docker lobby-web 재배포..."
run "docker compose --profile web up -d lobby-web"

# Healthcheck wait
echo ""
echo "Healthcheck 대기 (max 60s)..."
if [ $DRY_RUN -eq 0 ]; then
  for i in $(seq 1 30); do
    sleep 2
    status=$(docker ps --filter "name=^ebs-lobby-web$" --format "{{.Status}}" || echo "missing")
    if echo "$status" | grep -q "healthy"; then
      echo "✅ ebs-lobby-web healthy ($((i*2))s)"
      break
    fi
    if [ "$i" = "30" ]; then
      echo "❌ healthcheck timeout — docker logs ebs-lobby-web 확인 필요"
      exit 3
    fi
  done
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo " ✅ 완료"
echo "════════════════════════════════════════════════════════════"
echo " BUILD_ID:  $BUILD_ID"
echo " 접속:      http://localhost:3000/"
echo " 검증:      로그인 화면 우측 하단 \"EBS v0.1.0 · $BUILD_ID\" 표시"
echo "════════════════════════════════════════════════════════════"
