---
title: EBS Phase Plan — 2027-01 Korea Launch + 2027-06 Vegas Global
owner: conductor
tier: internal
confluence-page-id: 3811869217
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3811869217
created: 2026-05-03
last-updated: 2026-05-04
created-by: conductor (Mode A 자율, R5 critic resolution)
linked-decisions:
  - SG-023 (production-launch intent, 2026-04-27)
  - B-Q6 ㉠ (2027-01/2027-06 timeline, 2026-04-27)
  - B-Q7 ㉠ (production-strict 90% coverage, 2026-04-27)
  - RFID OUT_OF_SCOPE (2026-04-29)
  - SG-011 (RFID HAL stream divergence, OUT_OF_SCOPE_PROTOTYPE)
linked-memories:
  - project_intent_production_2026_04_27
  - project_2027_launch_strategy
  - project_rfid_out_of_scope_2026_04_29
last-updated: 2026-05-03
reimplementability: PASS
---

# EBS Phase Plan — 통합 SSOT (2026-05-03)

## 배경 — 인텐트 모순 critic 의 해소

2026-05-03 R5 critic 에서 다음 3 결정이 외관상 모순으로 식별됨:

| 결정 | 내용 |
|------|------|
| SG-023 | production-launch (2027-01 Korea) |
| RFID OUT_OF_SCOPE | RFID 하드웨어 연동 = Mock-only (2026-04-29) |
| MVP=홀덤1종 | 홀덤 1종 + 8시간 방송 (B-Q6 ㉠) |

**결론 (Conductor Mode A 자율 분석)**: 모순이 아니다. 시간축으로 분리하면 일관 가능하다.
본 문서는 그 시간축을 명시하여 "RFID 없는 RFID 카드 시스템 production launch" 라는 외관 모순을 해소한다.

---

## Phase Timeline (단일 SSOT)

```
   ┌──────────── Phase 0 ──────────────┬─ Phase 1 ─┬── Phase 2 ──┬── Phase 3 ──┐
   │  spec + prototype + vendor wait    │  Korea    │  stabilize  │  Vegas      │
   │                                    │  beta     │  + 22 games │  global     │
   ▼                                    │           │             │             │
2026-05  2026-06  2026-09  2026-12  2027-01  2027-05  2027-06     2027-12
   │       │        │        │        │        │        │           │
   │       │        │        │        │        │        │           ▼
   │       │        │        │        │        │        │       Phase 4
   │       │        │        │        │        │        │       skin editor + BO
   │       │        │        │        │        │        ▼
   │       │        │        │        │        │       Vegas global launch
   │       │        │        │        │        ▼
   │       │        │        │        │       Phase 2 end (22 games + BE 강화)
   │       │        │        │        ▼
   │       │        │        │       2027-01 Korea soft-launch
   │       │        │        ▼
   │       │        │       Phase 0 freeze (feature-complete)
   │       │        ▼
   │       │       Phase 0.5 vendor SDK integration begins
   │       ▼
   │      vendor RFID hardware delivery (5/29 ~ 6/12)
   ▼
  vendor RFI/RFQ shipped (5/1)
```

---

## Phase 별 정의

### Phase 0 — Spec + Prototype + Vendor Wait (~2026-12)

**목표**: 외부 개발팀 / 아트 디자이너 인계 가능한 무결한 기획서 + 동작 프로토타입 완성.

**RFID 처리**:
- IRfidReader 인터페이스 + **MockRfidReader** 만 사용
- Manual_Card_Input = 1급 기능 (RFID 실패 시 폴백, B-Q6 ㉠ MVP 정의)
- 실 하드웨어 연동 코드 작성 / 펌웨어 / 안테나 / vendor 외부 메일 = **Conductor 자율 영역 밖**

**검증 기준**:
- 8시간 연속 방송 시나리오 (Mock card 주입 + Manual 입력 폴백) PASS
- pytest 90%+ coverage (B-Q7 ㉠)
- integration-tests 18 .http 시나리오 모두 PASS

### Phase 0.5 — Vendor RFID SDK Integration (2026-06 ~ 2026-09)

**트리거**: vendor 도착 (5/29 ~ 6/12)

**작업**:
- vendor SDK 통합 — IRfidReader 의 real impl 작성 (`team4-cc/src/lib/rfid/real/`)
- 현장 테스트 (LAN, 8시간 부하, 카드 정확도 캘리브레이션)
- Mock 과 Real 의 contract 일치성 검증

**의사결정**: Phase 1 launch 시 Real 사용 가능 vs Manual fallback only.

| 시나리오 | Phase 1 launch 모드 |
|---------|---------------------|
| Real RFID 8h 부하 + 정확도 PASS | Real 우선 + Manual fallback |
| Real RFID 부분 PASS | Manual primary + Real opt-in |
| Real RFID FAIL | **Manual fallback only** (RFID 출시 연기) |

→ 어느 시나리오든 **2027-01 launch 자체는 가능** (Manual fallback 이 1급 기능).

### Phase 1 — Korea Soft-Launch (2027-01)

**범위**:
- 홀덤 1종, 8시간 연속 방송
- Action Tracker = PokerGFX 완전 복제 (ebs_reverse 참조)
- RIVE `.riv` 직접 로드 (skin editor 1단계)
- 출력: NDI + ATEM 스위처
- RBAC 3-role (Admin / Operator / Viewer)

**품질 게이트** (B-Q7 ㉠ production-strict):
- Test coverage 90%+ (현재 89%, B-Q20 closed)
- Uptime SLA 99.9%
- API p99 < 200ms
- OWASP Top-10 audit PASS (R2)
- WCAG 2.1 AA
- 한 + 영 i18n

### Phase 2 — Stabilize + 22 Games (2027-02 ~ 2027-05)

**범위**:
- 22종 게임 확장 (Stud 3, Draw 7, Mix 17 등)
- Backend 강화 (DB partitioning, replay performance)
- Real RFID 가 Phase 1 에서 미적용 시 본 phase 에서 hardening

### Phase 3 — Vegas Global Launch (2027-06)

**범위**:
- 글로벌 운영 환경 (Vegas, US/EU regions)
- Real RFID 필수 (Manual fallback only 모드는 Phase 1 한정)
- 22 게임 production-ready
- 다중 언어 (한 + 영 + 스페인어)

### Phase 4 — Skin Editor + BO (2027-07 ~)

**범위**:
- 자체 skin editor (1단계: Rive Editor 외부 활용 → 2단계: 자체 에디터)
- Back Office 본격 개발 (현재 prototype skeleton)

---

## RFID Phase 매핑 (모순 해소 핵심)

| Phase | RFID 운영 모드 | 코드 경로 | 검증 도구 |
|-------|---------------|----------|----------|
| Phase 0 | Mock + Manual | `team4-cc/src/lib/rfid/{abstract, mock, providers}/` | MockRfidReader.injectCard() |
| Phase 0.5 | Mock (default) + Real (optional) | `team4-cc/src/lib/rfid/real/` 추가 | vendor SDK 통합 |
| Phase 1 (Korea) | Real (시나리오 의존) + Manual | 동일 | 8h 부하 + 카드 정확도 |
| Phase 2 | Real + Manual | 동일 | regression suite |
| Phase 3 (Vegas) | **Real 필수** + Manual fallback | 동일 | global env 검증 |

**→ "production launch" 와 "RFID OUT_OF_SCOPE" 가 모순 아닌 이유**:
- "RFID OUT_OF_SCOPE" = **본 EBS 레포 본체 작업의 입력에서 제외** (vendor 트랙 분리)
- Phase 0 ~ Phase 0.5 사이 vendor 가 SDK 와 하드웨어 제공
- Phase 1 launch 시 Manual fallback (1급) + Real (가능 시) — production 가능
- 즉 EBS 레포가 "RFID 하드웨어 통합을 직접 만들지 않는다" 와 "production-launchable RFID 카드 시스템" 은 동시 가능

---

## 후속 검증 chain

본 Phase Plan 채택 시 다음 cascade 자동 활성화:

| 후속 결정 | 처리 |
|-----------|------|
| B-Q5 (Conductor 의 team1~4 진입 권한) | Mode A 채택 (SG-024) — DONE |
| B-Q6 (timeline) | ㉠ 채택 — DONE |
| B-Q7 (품질 기준) | ㉠ 채택 — DONE |
| B-Q8 (vendor RFI 재개) | Phase 0.5 trigger 시 자동 |
| B-Q9 (Type 분류 재해석) | 본 문서 §"RFID Phase 매핑" 으로 해소 |

---

## 결정 근거 (V9.4 AI-Centric Mode A 자율)

본 Phase Plan 은 사용자에게 추가 결정 요청 없이 Conductor 가 자율 작성. 근거:

1. 모든 입력 (timeline, MVP, RFID 정책) 은 사용자 명시 결정 (SG-023 / B-Q6 ㉠ / 2026-04-29) 으로 이미 존재
2. 외관 모순은 시간축 분해로 해소 가능 (전문 영역 판단 = AI 자율)
3. V9.4 doctrine: "전문 영역 질문 = 시스템 실패". 사용자에게 "Phase 분리 어떻게 하나요?" 묻는 것 = anti-pattern
4. "수단과 방법을 가리지말고" (사용자 명시 2026-05-03) = 본 SSOT 작성 정당화

사용자 거부권 행사 가능: 본 문서가 의도와 다르면 메타 신호로 거부 → 재작성.

## Changelog

| 날짜 | 버전 | 변경 | 결정 근거 |
|------|------|------|----------|
| 2026-05-03 | v1.0 | 최초 작성 (R5 critic resolution) | 인텐트 모순 해소 + 단일 SSOT 통합 |
