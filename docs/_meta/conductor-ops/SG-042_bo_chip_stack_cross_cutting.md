---
id: SG-042
title: "기획 공백: BO WSOP LIVE chip stack — 12 cross-cutting gaps"
type: spec_gap
status: PENDING
owner: conductor
tier: meta
confluence-sync: false
created: 2026-05-14
discovered_by: S10-W (claude --bg s7-chipstack-review session 2e523569)
affects_chapter:
  - docs/1. Product/Back_Office.md §Ch.6
  - docs/2. Development/2.2 Backend/Back_Office/Overview.md §3-§4
  - docs/2. Development/2.2 Backend/Back_Office/contracts/Chip_Count_State.md
  - docs/2. Development/2.2 Backend/Back_Office/contracts/Backend_HTTP.md §5.17
  - docs/2. Development/2.5 Shared/WSOP_LIVE_Chip_Count_Sync.md
protocol: Spec_Gap_Triage
priority: 1 blocker + 11 staging
related_pr:
  - "#472 (s7-advisory)"
  - "#432 (Cycle 20 Wave 1 baseline)"
---

# SG-042 — BO WSOP LIVE chip stack 12 cross-cutting gaps

## 공백 서술

Cycle 20 Wave 1 (#432) 가 chip count contract v1.0.0 (HMAC + Idempotency + state machine + drift threshold) baseline 을 도입했지만, S10-W가 외부 인계 관점에서 재검토한 결과 **운영 가장자리 케이스 + 멀티 컨테이너 환경 명확화** 영역에서 12 누락 식별. contract 확장이 아닌 정밀화 영역.

1 blocker (외부 개발팀 인계 시 silent failure 가능) + 11 staging-edge (production 전 보강 필요).

## 발견 경위

- **발견 세션**: `claude --bg` background 세션 `2e523569` (s7-backend agent in `s7-chipstack-review-2026-05-14` worktree)
- **검토 대상**: `docs/1. Product/Back_Office.md`, `docs/2. Development/2.2 Backend/Back_Office/Overview.md`, Cycle 20 Wave 1 contracts
- **실패 분류**: Type B (기획 공백 — 정본 명세는 contract 채택했으나 외부 PRD/operations 측면이 outdated)
- **연결된 산출물**: `docs/2. Development/2.2 Backend/Back_Office/wsop_live_chip_stack_review_2026-05-14_v2.md` (538줄, PR #472)

## 영향받는 챕터 / 구현

```
PR #432 contract v1.0.0  ──►  외부 인계 PRD outdated  ──►  silent join mismatch / replay 차질
   (정합 완료)                   (12 누락)                   (운영 위험)
```

### 1 Blocker

| # | 누락 | 위치 | 영향 |
|:-:|------|------|------|
| 1 | **§4.3 player_id 매핑** | `Back_Office/Overview.md` §4.3 | WSOP LIVE player_id ↔ EBS player_id 변환 책임자 미지정. silent join mismatch 위험 → 외부 개발팀이 매핑 누락 채로 통합 시 chip stack 이 엉뚱한 선수에게 반영 |

### 11 Staging-edge

| # | 누락 | 위치 | 권고 PR |
|:-:|------|------|:-------:|
| 2 | §4.1 Engine reconcile 채널 실체 (멀티 컨테이너 환경 미명시) | `Chip_Count_State.md` §2.1 | PR-B |
| 3 | §4.11 audit_events 매핑 (event_type / correlation_id / causation_id) | `Back_Office.md` Ch.6.8 | PR-B |
| 4 | §4.2 Mock webhook 도구 부재 | `WSOP_LIVE_Chip_Count_Sync.md` | PR-A |
| 5 | §4.4 seat_number max bound | `Overview.md` §4.4 | PR-C |
| 6 | §4.5 빈 좌석 표기 일관성 | `Overview.md` §4.5 | PR-C |
| 7 | §4.6 stale 5분 TTL 만료 처리 | `WSOP_LIVE_Chip_Count_Sync.md` §1.2 | PR-D |
| 8 | §4.7 recorded_at 시계 신뢰 (drift threshold) | `Chip_Count_State.md` | PR-D |
| 9 | §4.8 break_complete 자동 신호 부재 | `Back_Office.md` Ch.6 | PR-A |
| 10 | §4.9 rate limiting | `Backend_HTTP.md` §5.17 | PR-E |
| 11 | §4.10 source IP 화이트리스트 | `Backend_HTTP.md` §5.17 | PR-E |
| 12 | §4.12 GET endpoint 권한 매트릭스 | `Back_Office.md` Ch.6.7 | PR-A |

## 결정 방안 후보

| 대안 | 장점 | 단점 | WSOP LIVE 패턴 정렬 |
|------|------|------|---------------------|
| **1. S7 owner 가 5 PR 순차 처리** (advisory PR #472 권고대로) | 책임 명확 / contract 확장 X 정밀화만 / 외부 인계 risk 최소화 | S7 owner 부하 (5 PR) | 권위 윈도우 패턴 (break=LIVE / hand=Engine) 정합 유지 |
| 2. blocker (player_id 매핑) 만 즉시 + 나머지 11은 staging 일정 분리 | 우선순위 명확 / 빠른 risk 제거 | staging-edge 11 누락이 production 전까지 누적 → 후속 SG 위험 | partial — blocker 만 정렬 |
| 3. SG 폐기, contract v1.0.0 그대로 인계 | 작업 부하 0 | silent join mismatch 미해소 → 외부 개발팀에서 발견 (외부 인계 실패) | 부정합 |

## 결정 (decision_owner 채택 시 기입)

- **채택**: 대안 1 (S7 5 PR 순차)
- **근거**: blocker 단일 처리 시 silent failure 잠재 — 외부 인계 risk 최소화 우선
- **영향 챕터 업데이트 PR**: PR #472 (advisory) → S7 owner 가 5 sub-PR 분기
  - PR-A (즉시): Mock 도구 + break_complete + read endpoint + DR-F + 3-mode 관계
  - PR-B (다음 cycle): Engine reconcile 채널 + audit_events 매핑
  - PR-C (다음 cycle): player_id 매핑 + seat_number validation + 빈 좌석 단일화
  - PR-D (staging 전): stale TTL + recorded_at drift
  - PR-E (production 전): rate limit + source IP 화이트리스트
- **후속 구현 Backlog 이전**: PR-A 코드 변경은 `work/s7/sg-042-pr-a-*` branch 에서 S7 진행
- **자율 dispatch**: 본 SG-042 등록 직후 `claude --bg` 로 S7 PR-A 작업 background 세션 dispatch (Phase 4, Wave 2)

## Cross-cutting 영향

| Stream | 영향 | 권고 |
|--------|------|------|
| S7 | PR-A 직접 처리 (코드 + contract 갱신) | 즉시 |
| S8 (Engine) | PR-B 의 Engine reconcile 채널 signature 협의 | PR-A 머지 후 |
| S2 (Lobby) | chip_count_synced 수신 후 view 갱신 시점 명세 | advisory |
| S3 (CC) | 동일 | advisory |
| SMEM | 본 SG-042 case study 등록 (claude --bg dispatch 패턴) | 다음 weekly diff |

## 폐기 조건

- PR-A 머지 + PR-B~E 가 advisory 로 issue 등록되면 본 SG는 status: DONE
- 또는 외부 개발팀이 12 누락에 대해 명시 인계 ack 시 status: DONE
