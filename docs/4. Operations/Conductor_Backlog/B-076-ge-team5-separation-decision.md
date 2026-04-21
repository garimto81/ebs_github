---
id: B-076
title: "Graphic Editor team5 분리 적합성 결정 (사용자 confirm 대기)"
status: PENDING
source: docs/4. Operations/Reports/2026-04-21-critic-graphic-editor-team5-separation.md
owner: conductor
created: 2026-04-21
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

## 사용자 confirm 필요 항목

1. 핵심이 (a) 팀 분리 (b) 도구 분리 (c) scope 확장 중 무엇인가?
2. "트리거 + DB 매핑" 구체 범위 — Rive state machine 시각편집 포함 여부?
3. 시급도 — 이번 세션 PRD 초안 vs 다음 세션?

## 후속 액션

사용자 결정 후 본 항목 IN_PROGRESS → DONE 처리. Option 별 후속 task 는 critic report §8 참조.

## 관련

- Critic Report: `docs/4. Operations/Reports/2026-04-21-critic-graphic-editor-team5-separation.md`
- 결정 이력: `docs/3. Change Requests/done/CR-conductor-20260410-ge-ownership-move.md` (CR-011)
- 현행 GE 기획: `docs/2. Development/2.1 Frontend/Graphic_Editor/Overview.md`
- 정책 SSOT: `docs/2. Development/2.5 Shared/team-policy.json` v7
- WSOP LIVE 정렬 자료: `wsoplive/.../EBS UI Design - Skin Editor.md` §3
