---
title: NOTIFY-S1 — 5-Act 시퀀스 명칭 drift (Foundation vs 정본)
owner: stream:S3 (Command Center)
target: stream:S1 (Foundation)
tier: notify
status: OPEN
last-updated: 2026-05-08
audit-source: docs/4. Operations/orchestration/2026-05-08-consistency-audit/
---

# NOTIFY-S1 — 5-Act 시퀀스 명칭 drift (Foundation vs 정본)

## 트리거

2026-05-08 Phase 0 정합성 감사 (S3 Command Center) 진행 중 발견. Foundation §3 / foundation_ssot §3 의 5-Act 시퀀스 명칭과 정본 `Command_Center_UI/Overview.md §3.0.4` 의 5-Act 명칭이 **표기 drift**. 의미는 동치 (운영자 인지 layer ↔ HandFSM 9-state 묶음) 이지만 운영자 / 개발자 인용 시 명칭 일관성 부재.

## 명칭 매핑

| Act | Foundation 명칭 (line 154 + foundation_ssot §3 + S3 spec) | 정본 명칭 (Overview.md §3.0.4 표) | 의미 layer |
|:---:|:---:|:---:|:---:|
| Act 1 | **Hand Start** | **IDLE** | IDLE 핸드 시작 인지 |
| Act 2 | **Deal** | **PreFlop** | 블라인드 + 홀카드 분배 |
| Act 3 | **Bet** | **Flop / Turn / River** | 베팅 라운드 |
| Act 4 | **Showdown** | **Showdown** ✅ 일치 | 핸드 공개 |
| Act 5 | **Hand End** | **Settlement** | 팟 분배 + 종료 |

## 의미 layer 차이

- **Foundation 명칭**: 운영자 인지 추상화 layer (5-Act 의 의미 묶음 SSOT)
- **정본 §3.0.4 명칭**: HandFSM 9-state 의 의미 묶음 (구현 layer)

같은 "5-Act 시퀀스" 이름으로 두 명칭 체계가 공존하므로 운영자 / 개발자가 인용 시 어느 명칭을 쓸지 혼동.

## 추가 위치 (확인 필요)

- `Foundation.md` line 154 — `Hand Start → Deal → Bet → Showdown → Hand End`
- `foundation_ssot.md` §3 (line 48) — 동일 명칭 (Foundation 추출)
- `Overview.md` §3.0.4 (line 332~338) — `IDLE / PreFlop / Flop·Turn·River / Showdown / Settlement`
- `Hand_Lifecycle.md` changelog (line 14) — `IDLE → PreFlop → Flop/Turn/River → Showdown → Settlement`
- `NOTIFY-S1-cc-identity-cascade-2026-05-07.md` (line 39) — `IDLE → PreFlop → Flop/Turn/River → Showdown → Settlement`

## 요청 (S1)

5-Act 명칭의 정점 SSOT 를 확정 + cascade:

- **Option A (Foundation SSOT 우선)**: Foundation §3 명칭 (Hand Start / Deal / Bet / Showdown / Hand End) 이 정점 → 정본 §3.0.4 의 "단계" column 을 운영자 인지 명칭으로 정정 + 9-state 매핑 column 으로 IDLE/PreFlop/... 보존. S1 + Conductor 협의로 정본 수정 인가.
- **Option B (정본 SSOT 채택)**: 정본 §3.0.4 의 9-state 묶음 명칭을 채택 → Foundation §3 + foundation_ssot §3 + S3 spec 의 명칭을 IDLE/PreFlop/... 으로 갱신. S1 영역.
- **Option C (양쪽 명칭 공존, 매핑 표 신설)**: 정본 §3.0.4 표에 "Foundation 명칭" column 추가 → 두 명칭 체계의 공식 매핑을 정본에 보존. S1 + Conductor 협의로 정본 수정 인가.

## S3 차단 영역

본 drift 는 S3 의 PR (#171, consistency audit 2026-05-08) 머지를 차단하지 않음 — 명칭은 다르지만 의미 동치, cascade 자체는 정합 완료. S1 결정 후 S3 재감사로 정합 마무리.

## 참조

- `docs/1. Product/Foundation.md` line 154
- `docs/4. Operations/orchestration/2026-05-08-consistency-audit/foundation_ssot.md` §3
- `docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md` §3.0.4
- `docs/2. Development/2.4 Command Center/Command_Center_UI/Hand_Lifecycle.md` (5-Act ↔ 9-state 매핑 SSOT 후보)
- 본 NOTIFY 의 audit-source 는 `docs/4. Operations/orchestration/2026-05-08-consistency-audit/` Phase 0 감사 spec
