---
title: Backlog
tier: internal
decomposed: true
---

# Backlog (디렉토리화됨)

## 🎯 2026-04-21 이관 우선 작업 (baseline 커밋 `7543452`)

팀 세션 시작 시 `team3-engine/CLAUDE.md §"2026-04-21 이관 시 우선 작업"` 섹션 필독.
전체 이관 가이드: `docs/4. Operations/Multi_Session_Handoff.md`

1. **CCR-050 Clock FSM 세부 구체화** — `BS_Overview §3.7` + team2 publisher (`publish_clock_detail_changed/reload_requested`) 정합
2. **NOTIFY-CCR-024 WriteGameInfo 22 필드** — `Overlay_Output_Events.md §6.0` 기반
3. **Draw 7종 + Stud 3종 완결** — `test/phase1~5` 커버리지 + edge case
4. **HandEvaluator 완결성** — Low hand, Split pot, Sidepot
5. **harness `/engine/health` endpoint** — team4 `engine_connection_provider` 가 health probe (SG-002)

### 관련 SG
- events 완전 PASS (21/21 D4) · SG-009 DONE (case serialization)

### 금지
- `lib/core/` 에 Flutter/HTTP/`dart:io` import (harness 만 허용)
- OutputEvent 신규 추가 시 `§6.0` 미동기화

---

이 파일은 멀티 세션 충돌 방지를 위해 **항목별 파일**로 분해되었습니다.

- 항목 위치: `./Backlog/` (18개 항목)
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
