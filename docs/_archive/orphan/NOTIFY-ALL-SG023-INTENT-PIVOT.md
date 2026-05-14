---
title: SG-023 인텐트 전환 (production 출시) — 전체 팀 broadcast + 작업 standby 권고
owner: conductor
tier: internal
type: notify-broadcast
recipients: [team1, team2, team3, team4]
broadcast-date: 2026-04-27
linked-sg: SG-023
linked-commit: (이번 turn commit)
status: ACTIVE
last-updated: 2026-04-27
confluence-page-id: 3819078326
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819078326/EBS+SG-023+production+broadcast+standby
---

## 공식 선언

> **EBS 의 프로젝트 인텐트가 전환되었습니다 (SG-023, 2026-04-27 사용자 결정).**
>
> 기존: EBS = 개발팀 인계용 기획서 완결 + 프로토타입 검증 (2026-04-20)
> **신규**: EBS = **production 출시 프로젝트** (2026-04-27)
>
> 본 결정은 SG-022 (단일 Desktop 바이너리) cascade 에 이은 **두 번째 큰 spec reversal** 이며, 거버넌스 / timeline / 품질 기준 등 후속 결정 영역이 광범위합니다.

## 1. 모든 팀 작업 — 일시 STANDBY 권고

본 broadcast 는 **NOTIFY-ALL-PHASE2-START.md (2026-04-27 직전 발행)** 의 §3 "팀별 진입 가능 작업" 을 **재해석 대상**으로 표시합니다.

### 표준 모델 (기존, 2026-04-27 직전):
- team1 합류 → Settings 5-level scope UI 구현 (프로토타입 수준)
- team2 합류 → SG-008-b 11건 endpoint 구현 (프로토타입 수준)
- team3 / team4 동시 작업

### 인텐트 변경 후 (현재):
- 각 팀의 작업이 **prototype-grade vs production-grade** 둘 중 어느 수준인지 후속 결정 대기
- **거버넌스 변경 가능성**: Conductor 의 team1~4 코드 영역 진입 권한 검토 중 (B-Q5)
- **timeline 명시 부재**: 런칭 일정 / MVP 정의 후속 결정 (B-Q6)

> **권고**: 각 팀은 진행 중 작업 완료 후 **일시 STANDBY**. Conductor 의 후속 cascade (B-Q5~Q9) 결정 후 새 NOTIFY 로 재개 신호 받음.

### 예외 (즉시 진행 가능):
- **SG-022 cascade 마무리** (B-Q3 team1 Web 빌드 자산 정리) — production 인텐트와 직교, 인프라 정리
- **순수 명세 보강** (Foundation 챕터 추가, BS_Overview 보완) — 인텐트 무관 spec 작업
- **Type A 버그 수정** (이미 명세된 동작의 명백한 구현 실수) — 인텐트 무관

## 2. 후속 결정 cascade 목록

Conductor 가 자율 진행 금지. 사용자 명시 결정 대기:

| Backlog ID | 결정 사항 | 영향 |
|:----------:|-----------|------|
| **B-Q5** | Conductor team 코드 영역 진입 권한 | 거버넌스 (Conductor vs 팀 세션 분리 모델 변경 가능) |
| **B-Q6** | timeline / MVP / 런칭 일정 | Roadmap.md 재작성, vendor reactivation 가능 |
| **B-Q7** | 품질 기준 (prototype-grade vs production-grade 측정) | "100% 검증" 의 정확한 정의 |
| **B-Q8** | vendor 모델 (RFI/RFQ 재개 여부) | `project_2027_launch_strategy` [LEGACY] 재활성 |
| **B-Q9** | Type 분류 (A/B/C/D) 의 production 의미 재해석 | `Spec_Gap_Triage.md` 갱신 |

## 3. 인텐트 비교 표

| 측면 | 2026-04-20 (이전) | 2026-04-27 (SG-023) |
|------|-------------------|---------------------|
| 프로젝트 목적 | 기획서 완결 (개발팀 인계) | production 출시 |
| 최종 산출물 | docs/ 기획 + team1~4/ 프로토타입 | docs/ 기획 + team1~4/ 구현 + 운영 인프라 |
| 사용자 역할 | 기획자 | 기획자 + production 출시 책임자 |
| 성공 기준 | 외부 개발팀 재구현 가능성 | 100% 검증된 완제품 + 운영 가능 |
| MVP / 런칭 | 범위 밖 | 후속 결정 필요 (B-Q6) |
| vendor 선정 | 범위 밖 (LEGACY) | reactivation 후보 (B-Q8) |
| Conductor 권한 | 기획서 편집장 + 완결성 판정 | 위 + ?(B-Q5 결정 대기) |

## 4. SG-022 cascade 와의 관계

SG-022 (단일 Desktop 바이너리) 는 SG-023 인텐트 전환과 **직교**. SG-022 cascade 는 그대로 유효하며, B-Q3 team1 web 정리는 인텐트 무관 진행 가능 (B-Q2 는 Conductor 가 처리 완료 2026-04-27).

## 5. 거버넌스 보호 선언 (Conductor)

Conductor 는 본 SG-023 cascade 에서 **인텐트 명시 변경만** 자율 처리. 다음은 **사용자 명시 결정 대기** 상태:

- ❌ team1~4 코드 영역 임의 진입 (CLAUDE.md "팀 세션 금지" 유지)
- ❌ timeline 자율 추정 (사용자 명시 부재)
- ❌ vendor RFI 재발송 (이전 [LEGACY] 명시)
- ❌ 품질 기준 임의 변경
- ❌ Type 분류 임의 재해석

## 6. 검증 (broadcast 도착 확인)

각 팀 세션 합류 시:

- [ ] 본 NOTIFY 읽기 완료
- [ ] memory `project_intent_production_2026_04_27.md` 읽기 완료
- [ ] CLAUDE.md (project) "🎯 프로젝트 의도" 섹션 갱신 확인
- [ ] 자기 팀 작업 진행 또는 STANDBY 결정
- [ ] Conductor 의 B-Q5~Q9 cascade 진행 상황 모니터링

## 참조

- `docs/4. Operations/Conductor_Backlog/SG-023-intent-pivot-production.md` (백로그 항목)
- `docs/4. Operations/Spec_Gap_Registry.md` (SG-023 row)
- `docs/4. Operations/Phase_1_Decision_Queue.md` Group E (사용자 결정 SSOT)
- `docs/4. Operations/Conductor_Backlog/NOTIFY-ALL-PHASE2-START.md` (이전 broadcast — §3 재해석 대상)
- memory `project_intent_production_2026_04_27.md` (NEW intent SSOT)
- 폐기: memory `project_intent_spec_validation` [SUPERSEDED], `user_role_planner` [SUPERSEDED]

## Changelog

| 날짜 | 버전 | 변경 내용 | 결정 근거 |
|------|------|-----------|----------|
| 2026-04-27 | v1.0 | broadcast 발행 (SG-023 인텐트 전환) | 사용자 B 옵션 채택 + cascade 재실행 |
