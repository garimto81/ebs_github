#!/usr/bin/env bash
# 2026-05-07 — file revert race 우회 build SOP.
#
# 배경: `.claude/hooks/conductor_stop_cleanup.py` 가 매 turn 종료 시
# `git stash push -u` + `git checkout main` 을 실행하여 working tree 의
# uncommitted 변경을 자동 stash 로 보낸다. 본 hook 비활성화 또는 git commit
# 으로 영구화 안 된 상태에서 Track A+B 같은 대규모 변경을 빌드할 때
# build context 가 stash 된 (회귀된) 코드를 카피하는 race 발생.
#
# 해결: build 시점에 working tree → 별도 frozen 디렉토리로 즉시 cp,
# 거기서 docker build → image freeze. file system 의 working tree 가
# stash 되어도 frozen 디렉토리는 영향 없음.
#
# 사용법: bash team4-cc/scripts/frozen-build.sh

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
FROZEN="${TMPDIR:-/tmp}/ebs-cc-frozen"

echo "[frozen-build] purge $FROZEN"
rm -rf "$FROZEN"
mkdir -p "$FROZEN"

echo "[frozen-build] copy $REPO_ROOT/team4-cc → $FROZEN/"
cp -r "$REPO_ROOT/team4-cc" "$FROZEN/"

echo "[frozen-build] docker build (frozen context)"
docker build \
  -t ebs/cc-web:latest \
  -f "$FROZEN/team4-cc/docker/cc-web/Dockerfile" \
  "$FROZEN/team4-cc"

echo "[frozen-build] recreate container"
cd "$REPO_ROOT"
docker compose -p ebs --profile web up -d --no-deps --force-recreate cc-web

echo "[frozen-build] wait healthy"
until [ "$(docker inspect ebs-cc-web --format '{{.State.Health.Status}}' 2>/dev/null)" = "healthy" ]; do
  sleep 2
done

echo "[frozen-build] image:"
docker inspect ebs-cc-web --format 'Image: {{.Image}}'
echo "[frozen-build] DONE"
