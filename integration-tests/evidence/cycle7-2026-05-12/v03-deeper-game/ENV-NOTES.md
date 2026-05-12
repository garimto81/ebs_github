# v03-deeper-game Execution Environment Notes

S9 Cycle 7 Wave 3 (issue #328). 2026-05-12.

## 실행 환경 메모

본 v03 e2e 는 **fresh dart engine harness** (`dart run bin/harness.dart --port=18083`)
에 대해 실행되었습니다. 이유:

### 컨테이너 stale issue (Cycle 6 와 동일 패턴)

- `ebs-engine` Docker 컨테이너 (port 18080) image build: 2026-05-11 08:53 UTC
- PR #319 (S8 Cycle 6 `[#310]` v03 multi-hand straddle + ante_override + RIT split) merge: 2026-05-12 07:53 UTC
- PR #320 (S9 Cycle 6 `[#311]` v02 multi-hand e2e) merge: 2026-05-12 07:53 UTC
- 컨테이너 `873b9bdbd9aa` 의 `/app/harness` binary (7.7 MB) 는 PR #319 / #320 / #301
  모두 머지 이전 빌드. 가동 23 시간 유지.
- 결과 — 컨테이너에 다음 라우트/필드 없음:
  - `POST /api/session/:id/next-hand` 라우트 → 404
  - `runItBoard2Cards` toJson 필드 → 미존재
  - `sbSeat` / `bbSeat` toJson 필드 → 미존재
  - `AnteOverride` 이벤트 handler → "Unknown event type" 400 응답

### 회피 방법 (S9 scope-aligned, Cycle 6 와 동일)

- ebs-engine 컨테이너 rebuild 는 S9 scope 외 (S11 / DevOps owns)
- 대신 본 worktree (`C:/claude/ebs/.claude/worktrees/s9-cycle7-328/team3-engine/ebs_game_engine/`)
  에서 `dart run bin/harness.dart --port=18083` 로 fresh harness 가동
- v03 시나리오를 :18083 에 대해 실행 → **9/9 phase PASS**

### 후속 action (S9 scope 외 — Cycle 6 ENV-NOTES.md 와 중복 트래킹)

- [ ] ebs-engine 컨테이너 rebuild (S11 / DevOps) — Cycle 6 NOTES 와 동일 이슈
- [ ] CI runner 의 `docker compose build engine` step 검증 — PR build 시
      매번 fresh build 보장되는지 확인 (`integration-tests-e2e.yml` workflow)
- [ ] v03 priority smoke step 은 CI 에서는 fresh 빌드로 PASS 가능 (workflow
      에 `docker compose --profile e2e up -d --build` 명시 가정)
- [ ] cascade `pipeline:env-broken` 후보 — broker publish 검토

## 시나리오 / Playwright 무관성

본 evidence + summary 의 PASS 결과는 다음 baseline 에 한정:

- **Engine harness 코드**: 본 worktree (`work/s9/cycle7-328-2026-05-12`) 의
  `team3-engine/ebs_game_engine/lib/harness/server.dart` 기준 (PR #319 머지된 origin/main 위)
- **포트**: 18083 (fresh dart 실행, ebs-engine 컨테이너 우회)
- **신규 endpoint** (v02 +  v03 cycle 6):
  - `POST /api/session/:id/next-hand` ✓ 가용
  - `AnteOverride` event handler ✓ 가용
  - `RunItChoice` event handler ✓ 가용
- **신규 schema 필드** (v03 cycle 6):
  - `sbSeat`, `bbSeat` ✓ toJson 노출
  - `runItBoard2Cards` ✓ toJson 노출
  - `straddleEnabled`, `straddleSeat`, `anteAmount`, `anteType` ✓ toJson 노출
- **회귀 baseline**:
  - v01 (Cycle 4 issue #248) — fold-to-BB 1-hand flow ✓ PASS
  - v02 (Cycle 5 issue #287) — POST /next-hand rotation ✓ PASS

## CI 재현

GitHub Actions runner 는 PR head 의 source 로 컨테이너를 빌드하므로 동일 결과를
재현해야 합니다. 만약 CI 에서 fail 하면:

1. 컨테이너 build cache 확인 — `docker compose build engine --no-cache`
2. 본 ENV-NOTES.md 의 baseline 코드 commit 과 CI runner 의 build context 일치 검증
3. `pipeline:env-broken` cascade broker publish — S11 통보

## Phase 결과 요약

| Phase | 검증 항목 | 결과 |
|:-----:|----------|:----:|
| A | Engine 가동 (health, variants) | ✓ PASS |
| B | Straddle hand-to-hand 회전 (3→4→5) | ✓ PASS |
| C | AnteOverride 영속화 (100 → next-hand → 100, 재override 200) | ✓ PASS |
| D | RunItChoice routing + runItBoard2Cards key shape | ✓ PASS |
| E | Combined straddle + ante 독립 작동 | ✓ PASS |
| F | v01 baseline 회귀 (fold-to-BB) | ✓ PASS |
| G | v02 baseline 회귀 (POST /next-hand) | ✓ PASS |
| H | 4-hand round-robin wrap-around (5→0→1) | ✓ PASS |
| I | Final DoD cumulative (5 session 영속화 검증) | ✓ PASS |

> **9/9 phase PASS** — Multi_Hand_v03.md §1/§2/§3 spec 완전 회귀 보장.
