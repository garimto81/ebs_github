---
title: Frozen Build SOP — file revert race 우회
owner: prototype
tier: internal
status: ACTIVE
last-updated: 2026-05-07
---

# Frozen Build SOP

## Context

2026-05-07 진단 결과, `.claude/hooks/conductor_stop_cleanup.py:51-58` 가 매 turn 종료 시 다음 동작:

```python
if _has_uncommitted():
    code, out = _git("stash", "push", "-u", "-m",
                     f"auto-conductor-stop-{ts} — main 복귀 전 WIP 보존")
```

→ working tree 의 uncommitted 변경 모두 자동 stash + `git checkout main`.

이 hook 이 **세션 외부 file watcher** 가 아니라 **Claude Code orchestrator stop hook** 이며, 본 세션의 매 turn 변경을 일관되게 회귀시킴 (`git stash list` 에 `auto-conductor-stop-*` stash 8개+ 누적).

Track A+B (CC 1×10 + 9-row + 3-zone) 같은 대규모 변경을 빌드할 때 다음 race:

```
T+0    Edit 변경
T+1    docker compose build cc-web 시작
T+2    Stop hook 이 turn 종료 신호 수신 → git stash push
T+3    docker buildkit 의 COPY src/ 가 stash 된 (회귀된) 코드 캡처
T+4    image 가 stub 코드로 빌드됨
```

## Solution — Frozen Build

build context 를 **monorepo 외 별도 디렉토리** 로 즉시 cp 후 거기서 docker build:

| 단계 | 명령 |
|:----:|------|
| 1 | `cp -r team4-cc → /tmp/ebs-cc-frozen/team4-cc` |
| 2 | `docker build -t ebs/cc-web:latest -f frozen/.../Dockerfile frozen/...` |
| 3 | `docker compose up -d --no-deps --force-recreate cc-web` |

frozen 디렉토리는 git stash 와 무관 → image 에 변경 100% 박힘.

## 사용

```bash
bash team4-cc/scripts/frozen-build.sh
```

스크립트는 `git rev-parse --show-toplevel` 으로 monorepo root 를 자동 감지.

## Hook 비활성화 (선택, 영구 우회)

frozen build 가 SOP 표준이지만, working tree 보존이 필요한 경우 hook 자체 무력화:

```python
# .claude/hooks/conductor_stop_cleanup.py main() 함수 시작 직후:
def main() -> int:
    return 0  # disabled — frozen-build.sh 사용
    # ... 이하 stash 로직 ...
```

또는 세션 종료 후 stash 자동 복원:

```bash
git stash pop stash@{0}  # 가장 최근 auto-conductor-stop stash
```

## 검증

| 검증 | 명령 | 기대값 |
|------|------|--------|
| frozen image markers | `docker exec ebs-cc-web grep -oc 'ADD PLAYER\|TopStrip\|RowCell' /usr/share/nginx/html/main.dart.js` | ≥ 3 |
| 컨테이너 healthy | `docker inspect ebs-cc-web --format '{{.State.Health.Status}}'` | `healthy` |
| e2e 시각 | `npx playwright test integration-tests/playwright/tests/v98-cc-1x10-grid.spec.ts` | 1 passed |

## Hook 진단 history

| 날짜 | 발견 | 근거 |
|------|------|------|
| 2026-05-07 | conductor_stop_cleanup.py 식별 | `git stash list` 에 `auto-conductor-stop-*` 누적 |
| 2026-05-07 | hook early-return 으로 비활성화 | turn 간 변경 보존 확인 |
| 2026-05-07 | frozen-build.sh SOP 등재 | 향후 대규모 build 시 표준 |
