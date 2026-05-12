# v02-2-hand-flow Execution Environment Notes

S9 Cycle 6 Wave 3 (issue #311). 2026-05-12.

## 실행 환경 메모

본 v02 e2e는 **fresh dart engine harness** (`bin/harness.dart --port=18082`) 에 대해 실행되었습니다. 이유:

### 컨테이너 stale issue (발견 사항)

- `ebs-engine` Docker 컨테이너는 23 시간 가동 (image created 2026-05-11 08:59Z)
- PR #301 (S8 Cycle 5 `[#287]` v02 multi-hand state) merge: 2026-05-12 05:45Z
- 컨테이너에는 `POST /api/session/:id/next-hand` 라우트가 없음 → 404
- Engine 코드 자체에 `_handleManualNextHandFull` 가 존재하지 않는 빌드

### 회피 방법 (S9 scope-aligned)

- ebs-engine 컨테이너 rebuild 는 S9 scope 외 (S11 / DevOps owns)
- 대신 `C:/claude/ebs/.claude/worktrees/s10a-cycle-6-p11/team3-engine/ebs_game_engine/`
  (PR #301 머지된 worktree) 에서 `dart run bin/harness.dart --port=18082` 로 fresh harness 가동
- v02 시나리오를 :18082 에 대해 실행 → 10/10 PASS

### 후속 action (S9 scope 외 — 별도 트래킹 필요)

- [ ] ebs-engine 컨테이너 rebuild (S11 / DevOps)
- [ ] CI runner 의 `docker compose build engine` step 확인 — PR build 시
      매번 fresh build 보장되는지 검증
- [ ] v02 priority smoke step 은 CI 에서는 fresh 빌드로 PASS 가능 (workflow
      에 `docker compose --profile e2e up -d --build` 이미 명시되어있음)

## 시나리오 / Playwright 무관성

본 evidence + summary 의 PASS 결과는 다음 baseline 에 한정:
- Engine harness 코드: PR #301 merged worktree 기준
- Endpoint: POST /api/session/:id/next-hand 가용 + 정상 동작
- Schema: handNumber, dealerSeat, seats[].isDealer, seats[].currentBet,
          seats[].status 모두 toJson 으로 노출 + 정상

CI 의 GitHub Actions runner 는 PR head 의 source 로 컨테이너를 빌드하므로
동일 결과를 재현해야 합니다. 만약 CI 에서 fail 하면 컨테이너 build cache
이슈 (불완전 invalidation) 를 의심해야 합니다.
