---
title: Backlog
tier: internal
decomposed: true
confluence-page-id: 3818717648
confluence-parent-id: 3811770578
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818717648/EBS+Backlog+0578
owner: S7
---

# Backlog (디렉토리화됨)

## 🔥 2026-04-22 Foundation 재설계 정렬 (최우선, 계획 수립 완료)

Foundation.md 가 2026-04-22 회의 7결정을 반영하여 전면 재설계됨 (F1 재작성 / Ch.4 2 렌즈 / §5.0 2 런타임 모드 / §6.3 통신 매트릭스 + 병행 dispatch / §6.4 DB SSOT 실시간 동기화 / §7.1 Overlay 배경 flag / §8.5 N PC 중앙 서버).

**team2 영향 분석 · 수정 계획**: `Engineering/Foundation_Realignment_Plan_2026-04-22.md`

Phase A (§6.4 발행 의무) → Phase B (BREAKING 정정) → Phase C (ADDITIVE 보강) → Phase D (Label 정리) → Phase E (판정 블록) 순서로 집행. 각 Phase 실행 시점에 개별 B-XXX 항목 등재 예정.

---

## 🎯 2026-04-21 이관 우선 작업 (baseline 커밋 `7543452`)

팀 세션 시작 시 `team2-backend/CLAUDE.md §"2026-04-21 이관 시 우선 작업"` 섹션 필독.
전체 이관 가이드: `docs/4. Operations/Multi_Session_Handoff.md`

1. **Fresh DB** — `python team2-backend/tools/init_db.py --force` (init.sql + alembic stamp head)
2. **IMPL-003 decks.py DB session** — `Conductor_Backlog/IMPL-003-team2-decks-db-session.md` (`TODO-T2-004`)
3. **settings_kv.py DB session** — `src/routers/settings_kv.py` in-memory → DB (`TODO-T2-011`)
4. **reports.py MV 실DB** — 6 endpoint mock → MV 쿼리 (`TODO-T2-009`)
5. **publishers.py trigger 연결** — `src/websocket/publishers.py` 20 event → router/service 호출 wiring (`TODO-T2-014`)
6. **SG-008 (a) 77 endpoint 실구현** — `Backend_HTTP.md §5.17` 편입 완료 → 코드 response schema + DB 연결
7. **SG-008 (b1~b9) 9 endpoint** — audit/auth/sync (`SG-008-b1~b9` 파일 참조)
8. **SG-008-b14 2FA migration 0006** — users 테이블 twofa_* 컬럼 + 6 endpoint
9. **NOTIFY-CCR-053 Users Suspend/Lock/Delete** + **NOTIFY-CCR-039 audit event_type 카탈로그**
10. **SG-004 .gfskin 업로드 검증** — `tools/validate_gfskin.py` 재사용 POST /api/v1/skins

### 관련 SG / IMPL
- SG-002/003/006/007/008/009 (RESOLVED/PARTIAL/DONE) · IMPL-003 · b1~b15 (승격 완료)

### 현 baseline
- pytest **247 tests 0 errors**
- drift: events/fsm/websocket 완전 PASS, api D3=0
- FSM canonical: `src/db/enums.py` 7종

---

이 파일은 멀티 세션 충돌 방지를 위해 **항목별 파일**로 분해되었습니다.

- 항목 위치: `./Backlog/` (66개 항목)
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
