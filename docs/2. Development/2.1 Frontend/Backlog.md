---
title: Backlog
tier: internal
decomposed: true
confluence-page-id: 3832873103
confluence-parent-id: 3811606750
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832873103/Backlog
owner: S2
---

# Backlog (디렉토리화됨)

## 🎯 2026-04-21 이관 우선 작업 (baseline 커밋 `7543452`)

팀 세션 시작 시 `team1-frontend/CLAUDE.md §"2026-04-21 이관 시 우선 작업"` 섹션 필독.
전체 이관 가이드: `docs/4. Operations/Multi_Session_Handoff.md`

1. **IMPL-002 Engine Connection UI 협력** — splash/router 연동 부분 (`Conductor_Backlog/IMPL-002-team4-engine-connection-ui.md`)
2. **Settings 5탭 교차검증** — UNKNOWN 5 → PASS (`Settings/{Outputs,Graphics,Display,Rules,Statistics}.md`)
3. **Quasar 잔재 정리 (SG-001 후속)** — `src/`, `package.json`, `node_modules/`, `quasar.config.js` 등 삭제
4. **skin-editor drafts 5 완결** — `Graphic_Editor/References/skin-editor/` PRD-0006/7/7-S1/7-S2 + PLAN-UI-001
5. **Chip_Management §6 미결 3건** — Multi-Table/Discrepancy/Color-up (Conductor 협의)
6. **features 정렬** — 선언 8 vs 실측 6 (reports 편입 or 3 신규 구현) — `Engineering.md §0` 참조

### 관련 SG
- `SG-001` DONE (Flutter 채택) / `SG-003` PARTIAL (Settings 6탭) / `SG-004` RESOLVED (.gfskin)

---

이 파일은 멀티 세션 충돌 방지를 위해 **항목별 파일**로 분해되었습니다.

- 항목 위치: `./Backlog/` (43개 항목)
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
