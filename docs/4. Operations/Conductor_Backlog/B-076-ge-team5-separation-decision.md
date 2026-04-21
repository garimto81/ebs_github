---
id: B-076
title: "Graphic Editor team5 분리 적합성 결정 (DONE — Option A 채택)"
status: DONE
source: docs/4. Operations/Reports/2026-04-21-critic-graphic-editor-team5-separation.md
owner: conductor
created: 2026-04-21
resolved: 2026-04-21
resolution: "사용자 결정 — Lobby 탭 위치 유지 + team1 owner 유지 + scope 확장 (BS-08-05~07 추가). team5 신설 폐기."
---

# B-076 — Graphic Editor team5 분리 적합성 결정

## 배경

사용자 요청 (`/team` 2026-04-21 03:50): "graphic editor 를 별도 설계하는 것에 대한 적합성에 대해 critic mode 로 검토 필요. Visual Studio처럼 확장성 넓은 트리거 기반 + DB 매핑 인프라 에디터" 비전 제시.

## Critic 결과

5-Phase 병렬 critic 완료. 옹호 (41/60) vs 반대 (43/60) — 거의 동일. 단일 안 채택 불가, 부분 채택 권고.

상세: `docs/4. Operations/Reports/2026-04-21-critic-graphic-editor-team5-separation.md`

## 결정 옵션

| Option | 비용 | Conductor 권고 |
|--------|:----:|:----:|
| A. team1 scope 확장 (BS-08-05~07 추가) | LOW | 차선 |
| **B. 도구 분리 + team1 owner 유지** | **MEDIUM** | **권고** |
| C. team5 신설 (옹호 critic 안) | HIGH | 비권고 (CR-011 폐기 사유 5/5 재발 위험) |

## 사용자 결정 (2026-04-21)

> "option b. lobby 의 탭 중 하나"

해석: Option B 의 "owner 유지" 측면은 채택, **"별도 앱 분리" 측면은 거부** (Lobby 탭 위치 유지). 본질적으로 **Option A (team1 scope 확장)** 와 동일한 결정.

### 확정 사항

| 항목 | 결정 |
|------|------|
| owner | **team1** (현행 유지) |
| 위치 | **Lobby `/graphic-editor` 탭** (현행 유지) |
| scope | **확장** — BS-08-05/06/07 신규 추가 (Trigger / DB Mapping / Extension Points) |
| team5 신설 | **폐기** |
| `team5-graphic_editor/` 디렉토리 | **archive 또는 삭제** (사용자 처분 confirm 후) |
| 별도 빌드 (`ebs_ge_studio.exe`) | **폐기** |

### 미확정 (후속 PRD 작성 전 필요)

1. **트리거+DB 매핑 구체 범위** — Rive state machine 시각편집 포함 여부, EBS 자체 trigger DSL 의 형태 (선언적 vs 절차적), DB 매핑이 team2 Schema.md 직접 binding 인지 derived view 인지
2. **시급도** — BS-08-05/06/07 PRD 초안 작성 시점 (이번 세션 vs 다음 세션)

## 후속 액션 (등록 완료)

| 액션 | 위치 | 상태 |
|------|------|:----:|
| 결정 CR 신규 작성 | `docs/3. Change Requests/done/CR-conductor-20260421-ge-scope-expansion.md` | DONE (이번 commit) |
| BS-08-05/06/07 PRD 작성 | `docs/2. Development/2.1 Frontend/Backlog/B-077-ge-scope-expansion-prd.md` | PENDING |
| `team5-graphic_editor/` 처분 | 사용자 confirm 후 | BLOCKED |

## 관련

- Critic Report: `docs/4. Operations/Reports/2026-04-21-critic-graphic-editor-team5-separation.md`
- 결정 이력: `docs/3. Change Requests/done/CR-conductor-20260410-ge-ownership-move.md` (CR-011)
- 현행 GE 기획: `docs/2. Development/2.1 Frontend/Graphic_Editor/Overview.md`
- 정책 SSOT: `docs/2. Development/2.5 Shared/team-policy.json` v7
- WSOP LIVE 정렬 자료: `wsoplive/.../EBS UI Design - Skin Editor.md` §3
