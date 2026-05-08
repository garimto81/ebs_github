---
type: notify
target: Conductor
priority: HIGH
filed: 2026-05-08
detected-by: S8
related-issue: "#167 (S8 consistency audit)"
related-pr: "#180 (s8-engine consistency audit 2026-05-08)"
---

# NOTIFY-Conductor: CI 인프라 blocker 4건 (Wave 2 영향)

## 배경

S8 정합성 감사 PR #180 (work/s8/2026-05-08-init → main) 의 CI gate 5건 fail 발견.
모두 S8 PR 이 도입한 변경과 무관한 pre-existing 이슈 — 정상 분류 시 Conductor 또는 다른 stream 의 책임.
Wave 2 (S2/S3/S4/S7) PR 들도 동일 blocker 에 부딪힐 가능성 매우 높음 → 일괄 정정 권장.

## CI 실패 4건 (5 jobs)

### B1 [HIGH] verify-scope / verify-phase — workflow config 에 S8 미등록

**실패 메시지**:
```
verify-scope: ##[error]Unknown stream: S8
verify-phase: KeyError: 'S8'
```

**근거**: `.github/workflows/verify-scope.yml` 또는 그 wraps 하는 stream config (e.g., `team_assignment_v10_3.yaml`) 에 S8 stream 정의 부재. Issue #167 / S8-engine.md 는 활성화되어 있으나 CI workflow 가 S6 까지만 인식.

**수정 위치**: `docs/4. Operations/team_assignment_v10_3.yaml` 또는 workflow 의 stream allowlist (S8, S7 도 동일하게 영향 받을 수 있음).

**책임**: Conductor (workflow + team_assignment 갱신 권한)

### B2 [HIGH] Validate frontmatter — orchestration / _archive 파일 10개 owner 누락

**실패 메시지**: `python tools/spec_aggregate.py --check` 가 다음 10개 파일에서 owner 누락 검출:

| 파일 | scope |
|------|:-----:|
| `docs/_archive/governance-2026-05/INDEX.md` | _archive |
| `docs/4. Operations/orchestration/2026-05-08-consistency-audit/conductor-spec.md` | orchestration |
| `docs/4. Operations/orchestration/2026-05-08-consistency-audit/stream-specs/S1-foundation.md` | orchestration |
| `.../S2-lobby.md` | orchestration |
| `.../S3-cc.md` | orchestration |
| `.../S4-rive.md` | orchestration |
| `.../S5-index.md` | orchestration |
| `.../S6-prototype.md` | orchestration |
| `.../S7-backend.md` | orchestration |
| `.../S8-engine.md` | orchestration |

**근거**: 모든 audit setup 파일이 frontmatter `owner` 필드 없이 작성됨. spec_aggregate.py 가 이를 검출하고 PR fail.

**수정**: 각 stream-spec 에 `owner: conductor` 추가 (또는 stream 별 owner: team1~team4). 1 commit 으로 일괄 정정 가능.

**책임**: Conductor (orchestration 디렉토리 소유)

### B3 [MEDIUM] Validate relative links (team1) — 2.1 Frontend/2.1 Frontend.md 5 broken links

**실패 메시지**:
```
docs/2. Development/2.1 Frontend/2.1 Frontend.md:87 → Graphic_Editor/References/skin-editor/ebs-ui-design-plan.md (404)
docs/2. Development/2.1 Frontend/2.1 Frontend.md:88 → ebs-ui-design-strategy.md (404)
docs/2. Development/2.1 Frontend/2.1 Frontend.md:90 → pokergfx-vs-ebs-skin-editor.prd.md (404)
docs/2. Development/2.1 Frontend/2.1 Frontend.md:92 → prd-skin-editor-layout-references.prd.md (404)
docs/2. Development/2.1 Frontend/2.1 Frontend.md:94 → skin-editor-layout-balance-solutions.md (404)
```

**책임**: S2 Lobby (2.1 Frontend 영역)

### B4 [MEDIUM] Validate relative links (conductor) — RIVE_Standards.md 2 broken image links

**실패 메시지**:
```
docs/1. Product/RIVE_Standards.md:207 → ../../1. Product/images/foundation/wsop-2025-paradise-overlay.png (404)
docs/1. Product/RIVE_Standards.md:214 → ../../1. Product/images/foundation/overlay-anatomy.png (404)
```

**근거**: `../../1. Product/...` 상대 경로가 자기 자신 위치에서 잘못 계산됨 (URL encoded `1.%20Product` 와 함께). 정정: `images/foundation/...` 또는 `./images/foundation/...`.

**책임**: S1 Product Foundation (1. Product 영역)

## S8 자체 검증 (S8 PASS)

| Gate | 결과 |
|------|:----:|
| `scope-check` | ✅ PASS (모든 변경 docs/2. Development/2.3 Game Engine/ 내) |
| `verify-deps` | ✅ PASS |
| `Validate relative links (team2)` | ✅ PASS |
| `Validate relative links (team3)` | ✅ PASS |
| `Validate relative links (team4)` | ✅ PASS |
| `EBS ↔ WSOP LIVE alignment` | ✅ PASS |
| `GitGuardian Security` | ✅ PASS |

→ S8 PR 이 도입한 변경은 깨끗. 5 gate fail 은 pre-existing infrastructure 이슈.

## Wave 2 영향

S2/S3/S4/S7 도 동일 4 blocker (B1-B4) 에 부딪힐 가능성 매우 높음. Wave 2 진행 전 일괄 정정 권장.

## 권장 처리

1. **Conductor**: B1 (workflow stream allowlist) + B2 (orchestration frontmatter owner) — single commit on main 으로 즉시 unblock
2. **S2 Lobby**: B3 (2.1 Frontend.md 5 broken links 정리)
3. **S1 Product Foundation**: B4 (RIVE_Standards.md 2 image paths 정정)

위 3개 commit 후 main 재실행 시 Wave 2 모든 PR (S2/S3/S4/S7/S8) gate green 가능.

## S8 PR 처리 권장

PR #180 자체는 S8 작업 정합성 감사 결과 (D1/D2/D3 정정 + B-356 backlog 신설) 가 깨끗하므로:
- (a) 본 NOTIFY 처리 후 재실행 → 자동 green → auto-merge, 또는
- (b) admin override 로 즉시 merge (pre-existing blocker 책임 분리 시)

PR description 에 본 NOTIFY 참조 링크 추가됨.
