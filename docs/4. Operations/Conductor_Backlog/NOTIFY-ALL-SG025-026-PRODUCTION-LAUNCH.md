---
title: SG-025 + SG-026 — Production timeline + Quality gates (B-Q6 ㉠ + B-Q7 ㉠ broadcast)
owner: conductor
tier: internal
type: notify-broadcast
recipients: [team1, team2, team3, team4]
broadcast-date: 2026-04-27
linked-sg: SG-025, SG-026
linked-decision: B-Q6 ㉠ + B-Q7 ㉠ (사용자 자율 상정 명시)
status: ACTIVE
last-updated: 2026-04-27
confluence-page-id: 3818947277
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818947277/EBS+SG-025+SG-026+Production+timeline+Quality+gates+B-Q6+B-Q7+broadcast
---

## 공식 선언

> **EBS production timeline + quality gates 가 확정되었습니다.**
>
> 사용자 명시 (2026-04-27 Mode A 자율 상정): B-Q6 ㉠ Legacy Reactivate + B-Q7 ㉠ Production-strict.

## 1. Timeline (B-Q6 ㉠ — SG-025)

| Phase | 기간 | 핵심 활동 |
|-------|------|----------|
| Phase 0 | ~ **2026-12** | MVP=홀덤1종 구현 + 검증 (현재 진행 중) |
| Phase 1 | **2027-01** | **런칭** (한국 시장 베타) |
| Phase 2 | 2027-02 ~ 2027-05 | 안정화 + 22종 게임 확장 + Backend 보강 |
| Phase 3 | **2027-06** | **Vegas** (글로벌 런칭) |
| Phase 4 | 2027-07 ~ | 스킨 에디터 + BO 본격 개발 |

**MVP 정의** (memory `project_2027_launch_strategy` REACTIVATED):
- 홀덤 1종, 8시간 연속 방송 가능
- Action Tracker = PokerGFX 완전 복제
- RIVE `.riv` 직접 로드 (스킨 에디터 1단계)
- RFID 수동 입력 폴백 = 1급 기능
- 출력: NDI + ATEM 스위처

## 2. Quality Gates (B-Q7 ㉠ — SG-026)

| 측정 영역 | 기준 (Production-strict) |
|----------|--------------------------|
| Test coverage | **95%+** (B-Q10 도달 plan) |
| Uptime SLA | 99.9% |
| API 응답 시간 | p99 < 200ms (BLANK-1 100ms 전체 파이프라인 + endpoint 마진) |
| 에러율 | < 0.1% |
| 보안 | OWASP Top 10 준수 (B-Q11 audit plan) |
| 접근성 | WCAG 2.1 AA |
| i18n | 한글 + 영어 |

## 3. 팀별 영향

### Team 1 (Frontend)
- B-Q13: 단일 Desktop 라우팅 구현 (P0, Phase 0)
- B-Q14: Settings 5-level scope UI (P1, Phase 0 후반)
- 95% coverage 도달 (B-Q10) — Flutter test framework
- WCAG 2.1 AA 준수

### Team 2 (Backend)
- 우선 작업 7번 (SG-008-b 9 endpoint 실구현) → B-Q15
- 우선 작업 8번 (2FA migration 0006) → B-Q15
- 95% coverage 도달 (B-Q10) — pytest, 현재 90% → 5%p gap
- OWASP audit (B-Q11) — pip-audit + bandit + ASVS Level 2
- p99 < 200ms 측정 (B-Q12)

### Team 3 (Game Engine)
- API-04 OutputEvent 발행 — 100ms 파이프라인 측정 기여 (B-Q12)
- Game Rules 22종 (Phase 2) — Phase 0 은 홀덤 1종만

### Team 4 (Command Center)
- SG-022 통합 (단일 Desktop 바이너리)
- RFID HAL 100ms 파이프라인 기여 (B-Q12)
- Rive 메타데이터 검증 (SG-021)

## 4. 잔여 결정 (B-Q8)

| ID | 상태 | 사유 |
|:--:|:----:|------|
| B-Q8 vendor reactivate (RFI/RFQ 재개) | PENDING | 외부 메일 발송 destructive — Mode A 한계, 사용자 명시 필요 |

## 5. Conductor Mode A 활용 가능성

거버넌스 v7.1 Mode A 활성. 본 SG-025/026 cascade 후 잔여 작업 (B-Q10~Q15) 은 **Conductor 또는 각 팀 세션** 모두 진행 가능. 단:

- **거버넌스 안정성**: 1주 내 4건 reversal 누적 (SG-022/023/024 + B-Q6/Q7) → 점진 진행 권장
- **기존 자산 보호**: team2 247 tests 0 errors. Conductor 가 Mode A 코드 작성 시 **기존 자산 read 후 surgical edit** 만 권장
- **사용자 검증 cycle**: 큰 변경 후 사용자 검증 단계 권장

## 6. 다음 turn 권고

| 옵션 | 의미 |
|:----:|------|
| A | B-Q15 SG-008-b 9 endpoint 실구현 (team2 우선 작업 7번) — Conductor Mode A 또는 team2 세션 |
| B | B-Q13 단일 Desktop 라우팅 구현 (team1 우선 작업) — Conductor Mode A 또는 team1 세션 |
| C | B-Q14 Settings UI 구현 (team1+team2 병렬) |
| D | B-Q10 95% coverage 도달 (team2 5%p gap 분석 + 단위 테스트) |
| E | B-Q8 vendor reactivate 결정 (사용자 명시 필요) |

## 검증

- [ ] 본 NOTIFY 읽기 (각 팀 세션 합류 시)
- [ ] Roadmap.md 갱신 확인
- [ ] memory `project_2027_launch_strategy` REACTIVATED 확인
- [ ] 자기 팀 영향 (§3) 검토 + Backlog 우선순위 정렬

## 참조

- `docs/4. Operations/Phase_1_Decision_Queue.md` Group G (B-Q6 ㉠ + B-Q7 ㉠)
- `docs/4. Operations/Spec_Gap_Registry.md` SG-025/026
- `docs/4. Operations/Roadmap.md` (Production timeline + Quality gates)
- memory `project_2027_launch_strategy.md` REACTIVATED, `project_intent_production_2026_04_27.md`
- 잔여 Backlog: B-Q8/Q10/Q11/Q12/Q13/Q14/Q15

## Changelog

| 날짜 | 버전 | 변경 내용 | 결정 근거 |
|------|------|-----------|----------|
| 2026-04-27 | v1.0 | broadcast 발행 (B-Q6 ㉠ + B-Q7 ㉠ — production timeline + quality gates) | 사용자 자율 상정 명시 |
