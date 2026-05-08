---
title: Backlog
tier: internal
decomposed: true
last-updated: 2026-05-08
---

# Backlog (디렉토리화됨)

## 🆕 2026-05-08 S8 정합성 감사 발생 항목

S8 consistency audit (Issue #167, PR #180) 결과 신규 등재:

| ID | Title | Priority | 발생 사유 |
|----|-------|:--------:|----------|
| [B-356](Backlog/B-356-oe-catalog-self-inconsistency.md) | OE 카탈로그 self-inconsistency (OutputEvent_Serialization vs Overlay_Output_Events) | P1 | D2 [HIGH] — publisher `output_event.dart` 실측 정본화 후속 작업 |
| [NOTIFY-Conductor](Backlog/NOTIFY-Conductor-2026-05-08-ci-infra-blockers.md) | CI 인프라 blocker 4건 escalation (#183~#186) | HIGH | PR #180 CI 5 fail 분석 → 외부 책임 분리 |

## 🆕 2026-04-22 Foundation.md v11 재설계 대응 (신규 등재)

Foundation.md 가 §4.4 설치 렌즈 / §5.0 2 런타임 모드 / §6.3 프로세스 경계 + 병행 dispatch / §6.4 Engine SSOT / §7.1 배경 config flag / §8.5 복수 테이블 등을 전면 재설계. team3 소유 기획 문서에 미반영된 항목을 아래 8개로 분해.

| ID | Title | Priority | Foundation 근거 |
|----|-------|:--------:|----------------|
| [B-330](Backlog/B-330-Foundation-Engine-별도-프로세스-전파.md) | Engine 별도 프로세스 원칙 API-04 전반 전파 | P0 | §6.3, §6.4 |
| [B-331](Backlog/B-331-harness-engine-health-endpoint.md) | harness `/engine/health` endpoint 신설 | P0 | §6.3 (Demo Mode fallback) |
| [B-332](Backlog/B-332-Engine-응답-게임상태-SSOT-명시.md) | Engine 응답 = 게임 상태 SSOT 명시 | P0 | §6.3 §1.1.1, §6.4 |
| [B-333](Backlog/B-333-Overview-22종-게임-12-7-3-분류표.md) | Overview 22 variant × 12/7/3 분류표 | P1 | §6.1 |
| [B-334](Backlog/B-334-OutputEventBuffer-런타임-3분법.md) | OutputEventBuffer 탭/다중창/Engine 3분법 | P1 | §5.0, §6.3 |
| [B-335](Backlog/B-335-WriteGameInfo-SSOT-재정의.md) | WriteGameInfo 22 필드 Engine/BO SSOT 분류 | P1 | §6.4 |
| [B-336](Backlog/B-336-Harness-배포-시나리오-보강.md) | Harness 배포 (Local vs 중앙 서버) 보강 | P2 | §6.3, §8.5 |
| [B-337](Backlog/B-337-Overlay-배경-투명-단색-이분법.md) | Overlay 배경 Foundation §7.1 이분법 정렬 | P2 | §7.1 |
| [B-338](Backlog/B-338-harness-세션-재시작-복구.md) | harness 세션 persistence (crash 복구) | P1 | §8.4, §8.5 |

실행 순서: B-330/B-331/B-332 (P0) → B-333/B-334/B-335/B-338 (P1) → B-336/B-337 (P2).

## 🎯 2026-04-21 이관 우선 작업 — Foundation §9.3 5단계 로드맵 기준 재정렬 (2026-04-22)

전체 이관 가이드: `docs/4. Operations/Multi_Session_Handoff.md`. Foundation §9.3 의 5단계 로드맵 (1.기초 / 2.NLH 안정성 / 3.9종 실전 / 4.22종 완성 / 5.AI) 에 매핑하여 우선순위 재정렬:

| 우선 작업 | 5단계 매핑 | 비고 |
|----------|:---------:|------|
| **CCR-050 Clock FSM 세부** | 2단계 (NLH 안정성) | BS_Overview §3.7 + team2 publisher 정합 |
| **HandEvaluator 완결성** (Low/Split/Sidepot) | 2단계 | NLH 방송 안정성 핵심 |
| **harness `/engine/health`** = B-331 | 2단계 | Demo Mode fallback (8시간 안정성) |
| **Draw 7종 + Stud 3종 완결** | 4단계 (22종 완성) | Flop 12 + Draw 7 + Stud 3 = 22 |
| **NOTIFY-CCR-024 WriteGameInfo** = B-335 | 크로스 단계 | Engine/BO SSOT 재정의 (Foundation §6.4 반영) |

### 관련 SG
- events 완전 PASS (21/21 D4) · SG-009 DONE (case serialization)

### 금지
- `lib/core/` 에 Flutter/HTTP/`dart:io` import (harness 만 허용)
- OutputEvent 신규 추가 시 `§6.0` 미동기화

---

이 파일은 멀티 세션 충돌 방지를 위해 **항목별 파일**로 분해되었습니다.

- 항목 위치: `./Backlog/` (활성 19 B-항목 + 2 NOTIFY = 21 항목, 2026-05-08 기준)
- 신규 항목 추가: `./Backlog/{ID}-{slug}.md` 작성 (frontmatter 필수)
- 통합 읽기 뷰: `tools/backlog_aggregate.py` 가 `_generated/` 에 자동 생성

신규 항목 frontmatter 예시:

```yaml
---
id: B-XXX
title: "항목 제목"
status: PENDING  # PENDING | IN_PROGRESS | DONE
source: (이 파일 경로)
---
```
