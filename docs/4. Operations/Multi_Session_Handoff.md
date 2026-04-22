---
title: Multi-Session Handoff Guide (2026-04-21)
owner: conductor
tier: internal
last-updated: 2026-04-21
reimplementability: PASS
reimplementability_checked: 2026-04-21
reimplementability_notes: "멀티 세션 이관 체크리스트 + 각 팀 지침 — 본 문서 자립 완결"
---

# Multi-Session Handoff Guide

> 2026-04-20~21 Conductor 세션에서 구조적 재정비 완료. 이제 팀별 세션으로 이관.
>
> **역할 구분** (두 멀티세션 문서):
> - **이 문서 (`Multi_Session_Handoff.md`)** — **2026-04-21 이관 스냅샷**: 현재 우선 작업, 21 문제 해결 대비표, 팀별 작업 list. "What to work on now?"
> - **`Multi_Session_Workflow.md`** — **영구 운영 방법**: worktree/subdir 선택, 팀 작업 표준 절차(시작/진행/병합/정리), 금지사항. "How to run multi-session?"
> 팀 세션 시작 시 둘 다 읽기 권장.

## 1. 이전 문제 → 해결 대비

| # | 문제 | 해결 |
|:-:|------|------|
| 1 | **Conductor ↔ BS_Overview ↔ team1 CLAUDE.md 3중 SSOT 모순** (Quasar/Flutter/Quasar) | SG-001 DONE — Flutter 채택 + 원칙 1 divergence justify. 3 문서 전체 정렬 (2026-04-20) |
| 2 | **"실제 제품 출시" 로 오해된 프로젝트 의도** | 2026-04-20 재정의: "개발팀 인계용 기획서 완결 프로토타입". CLAUDE.md 최상위 전제 주입 |
| 3 | **"앱 실행 거의 모두 실패"** | Type A/B/C 프로토콜 + `Spec_Gap_Triage.md` 프로토콜 체계. 빌드 실패 = 기획 공백 신호로 해석 |
| 4 | **기획 ↔ 코드 Spec Drift 감지 부재** | `tools/spec_drift_check.py` 7 계약 자동 scanner + `Spec_Gap_Registry.md` + `.claude/hooks/pre_push_drift_check.py` |
| 5 | **"코드가 진실" 오판 위험** | `Spec_Gap_Triage.md §7.2.1` 3 요건 (30일 CI 녹색 + 앱 안정 + 구현자 확인). 미충족 → 기획 진실 default |
| 6 | **팀 Backlog 혼잡 (100 NOTIFY-CCR)** | `tools/archive_legacy_backlog.py` — 100 파일 `_archived-2026-04/` 이동. 실제 작업 대상만 남음 |
| 7 | **hook 상대경로 blocking** (cd team*/ 후) | `.claude/settings.json` 전체 `${CLAUDE_PROJECT_DIR}` 절대경로화 |
| 8 | **Engine 의존 graceful 계약 부재** | SG-002 RESOLVED — ENGINE_URL dart-define + 3-stage state machine + Demo Mode fallback |
| 9 | **Settings 6탭 스키마 부재** | SG-003 PARTIAL — 4-level scope (Global/Series/Event/Table/User) + `settings_kv` 테이블 + 6탭 master |
| 10 | **.gfskin 포맷 미정** | SG-004 RESOLVED — JSON Schema + validate_gfskin.py + sample ZIP |
| 11 | **Foundation Ch.6 시스템 연결 도식 부재** | SG-005 RESOLVED — Engine↔BO REST Option A 확정, EBS_Core.md 병합 폐기 |
| 12 | **RFID 52 카드 codemap 미정** | SG-006 RESOLVED — Deck 개념 + 3 등록 모드 + in-memory test (13 pass) + Demo deck seed |
| 13 | **Reports API 6건 기획 공백** | SG-007 RESOLVED — 6 endpoints full spec + 공통 envelope + RBAC 매트릭스 + 13 test |
| 14 | **89 code-only API endpoint (D3)** | SG-008 재정의 (역방향 문서화 폐기) — (a) 77 `§5.17` 편입 / (b) 12 개별 승격 SG-008-b1~b12 / (c) 3 삭제 |
| 15 | **17 로우 settings code-only 필드** | SG-008-b13 triage (13 기획 편입 Graphics/Rules §신규 서브그룹) + b14 2FA + b15 NDI Fill/Key |
| 16 | **TableFSM case drift** | SG-009 DONE — BS_Overview §3.1/§3.3 직렬화 규약 (display=UPPERCASE / wire=lowercase) |
| 17 | **scanner false positive 과다** | SG-010 HIGH — schema inline code 제거, websocket 카탈로그 테이블만, settings 대칭 정규화, fsm engine lib 전체 scan, api markdown table cell 인식 |
| 18 | **RFID 6-stream divergence** | SG-011 OUT_OF_SCOPE — 프로토타입 범위 밖, 하드웨어 SDK 기반 개발팀 확정. `out_of_scope_prototype: true` 플래그 |
| 19 | **websocket publisher 20 미구현** | J2 완료 — `src/websocket/publishers.py` (20 event skeleton) + 5 test PASS. D2 20→0, D4 24→44 완전 PASS |
| 20 | **migration 0002 batch_alter_table NoSuchTableError** | J1 — 0002 idempotent 재작성 + `tools/init_db.py` (init.sql + alembic stamp head 자동화, 25 tables) |
| 21 | **FSM enum code 미정의** | M3 — `team2-backend/src/db/enums.py` 신규 (TableFSM/HandFSM/SeatFSM/PlayerStatus/DeckFSM/EventFSM/ClockFSM 7종 canonical) |

## 2. 현 상태 집계

### drift (4 계약 완전 PASS)

| Contract | D1 | D2 | D3 | D4 | 상태 |
|----------|:--:|:--:|:--:|:--:|:----:|
| **events** | 0 | 0 | 0 | 21 | ✅ PASS |
| **fsm** | 0 | 0 | 0 | 23 | ✅ PASS |
| **rfid** | 0 | 0 | 0 | 8 | ✅ OUT_OF_SCOPE |
| **websocket** | 0 | 0 | 0 | 44 | ✅ PASS |
| schema | 0 | 1 | 2 | 23 | 거의 |
| api | 7 | 42 | 0 | 114 | D3 완전 해소 |
| settings | 0 | 97 | 17 | 39 | SG-003 PARTIAL |

### audit (계약 문서 93개)

| State | Count | Ratio |
|-------|:-----:|:-----:|
| PASS | 75 | 81% |
| UNKNOWN | 15 | 16% |
| FAIL | 0 | 0% (SG-002 RESOLVED 2026-04-20, Foundation §6.3 §6.4 §7.1 — B-203 집계 동기화 2026-04-22) |
| N/A | 3 | 3% |

### 테스트

- pytest team2: **247 tests collected, 0 errors**
- dart analyze team3/team4: **0 errors**
- init_db.py: **25 tables + alembic stamp head 성공**

## 3. 공통 지침 (모든 세션)

### 🚀 표준 명령 (2026-04-21 이후)

**모든 작업은 `/team` 스킬로 수행**:

```bash
/team "<task description>"     # 8 Phase 자동 실행 (Workflow v3.0)
```

Phase: Context detect → Pre-sync → Execute (`/auto`) → Verify → Commit → Main ff-merge → Push → Report.
세션 시작/종료 불필요. 매 호출이 완결된 트랜잭션.

스킬 상세: `~/.claude/skills/team/SKILL.md`
정책: `docs/4. Operations/Multi_Session_Workflow.md` v3.0

### 핵심 원칙 (CRITICAL)

1. **기획이 진실 default** — 코드가 안정적 + CI 녹색 + 구현자 확인 3 요건 모두 충족 시에만 "코드가 진실" 판정
2. **Type 분류 먼저** — 빌드/테스트 실패 시 A(구현실수) / B(기획공백) / C(기획모순) / D(drift) 중 판정 후 대응
3. **SG 승격 패턴** — 결정 애매 → `Conductor_Backlog/SG-XXX-*.md` 승격, default 채택 + decision_owner notify
4. **일괄 UNKNOWN 도배 금지** — audit frontmatter 는 판정 근거 있을 때만
5. **계약 문서만 audit** — README/Backlog/NOTIFY 에 frontmatter 강요 금지
6. **`/team` 통한 작업** — 수동 git commit/push 최소화. conflict 발생 시만 수동 개입

### 워크플로우

1. **세션 시작 시**: `git pull origin main` + `python tools/spec_drift_check.py --all` 로 baseline 확보
2. **작업 중**: `Spec_Gap_Triage.md` 프로토콜 준수. 공백 발견 시 SG 승격
3. **커밋 전**: 해당 계약의 scan 재실행, drift 증가 없는지 확인
4. **push 전**: pre-push hook 이 자동 scan (non-blocking 경고)

### 브랜치 / 세션 격리

- Conductor=`main` 직접
- team=`work/team{N}/{YYYYMMDD}-slug` (SessionStart hook 자동)
- 팀 병합: `/team-merge` 커맨드 (Conductor 세션)
- 팀 소유 파일 수정 시: decision_owner notify (v7 free_write + decision_owner)

## 4. 팀별 특화 지침

### team1 Frontend

**경로**: `team1-frontend/lib/`
**기술**: Flutter/Dart + Riverpod + Freezed + Dio + go_router + rive
**SessionStart**: `work/team1/{date}-slug` 자동

**우선 작업**:
- Settings 5탭 (Outputs/Graphics/Display/Rules/Statistics) 레거시 ↔ SG-003 교차검증 — 현재 UNKNOWN 5
- Quasar 잔재 정리 (`src/`, `package.json`, `node_modules/`, `quasar.config.js`, `pnpm-lock.yaml`) — SG-001 후속
- skin-editor drafts 5 PRD 완결
- `Chip_Management.md` §6 미결 3건 (Multi-Table 일괄 API, Chip Discrepancy, Color-up/Race-off)
- Features 정렬 (선언 8: players/audit_log/hand_history vs 실측 6: reports) → `Engineering.md §0` 참조
- IMPL-002 Engine Connection UI (`router_guard` + `engine_connection_banner`) — banner/splash skeleton 이미 있음, 실동작 wiring

**참조 SSOT**:
- `docs/2. Development/2.1 Frontend/Settings/*.md` (6탭)
- `docs/4. Operations/Conductor_Backlog/SG-003-*.md`
- `lib/features/settings/providers/settings_scope_provider.dart` (4-level override)
- `lib/features/settings/providers/preferences_provider.dart`

### team2 Backend

**경로**: `team2-backend/src/`
**기술**: FastAPI + SQLModel + Alembic + Pydantic
**Fresh DB workflow**: `python team2-backend/tools/init_db.py --force`

**우선 작업**:
- decks/settings_kv in-memory → DB session 교체 (IMPL-003 / `TODO-T2-004/011`)
- `reports.py` MV 실DB 쿼리 교체 (`TODO-T2-009`)
- `publishers.py` 20 event 를 실제 trigger 에 연결 (`TODO-T2-014`)
- SG-008 (a) 77 endpoint Backend_HTTP §5.17 편입 → **라우터 실구현** (대부분 skeleton 존재)
- SG-008-b 옵션 반영 (b1~b9 기획 추가 endpoint 실구현 — audit/auth/sync)
- NOTIFY-CCR-053 Users Suspend/Lock/Delete 3상태
- NOTIFY-CCR-039 audit_events event_type 카탈로그 정식화
- SG-004 .gfskin 업로드 검증 endpoint (`validate_gfskin.py` 활용)

**참조 SSOT**:
- `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md` §5.17
- `docs/2. Development/2.2 Backend/APIs/Backend_HTTP_Status.md` (2026-04-20 audit)
- `src/db/enums.py` (7 FSM canonical, 신규)
- `src/websocket/publishers.py` (20 event skeleton, 신규)

**pytest**: `python -m pytest team2-backend/tests/` — 247 baseline 유지

### team3 Game Engine

**경로**: `team3-engine/ebs_game_engine/`
**기술**: 순수 Dart (단 `bin/harness.dart` + `lib/harness/` 는 `dart:io` 허용)

**우선 작업**:
- CCR-050 Clock FSM 세부 구체화
- NOTIFY-CCR-024 WriteGameInfo 22 필드 스키마
- Draw 7종 + Stud 3종 variant 구현 완결성 검증 (test/ 에 phase1-5 존재)
- HandEvaluator edge case 커버리지

**참조 SSOT**:
- `docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md` §6.0 (21 카탈로그)
- `docs/2. Development/2.3 Game Engine/Behavioral_Specs/**`
- `docs/1. Product/Game_Rules/**` (Confluence 발행 대상, 독립 완결)

**금지**:
- `lib/core/` 와 `lib/engine.dart` 는 순수 Dart (Flutter/HTTP/dart:io 금지)
- OutputEvent 신규 추가 시 반드시 `Overlay_Output_Events.md §6.0` 동시 업데이트

### team4 Command Center

**경로**: `team4-cc/src/lib/`
**기술**: Flutter/Dart + Riverpod + Dio + rive

**ENGINE_URL**: `--dart-define=ENGINE_URL=http://host:port` (default `http://localhost:8080`)

**우선 작업**:
- IMPL-002 후속 (`engine_connection_banner` + `splash_screen` 기본 구현 완료 → UI 테스트 + e2e)
- Overlay Rive 가 21 OutputEvent 전부 consume 검증
- SG-006 Deck 등록 3 모드 구현 (스캔 / 벌크 / 자동 순서)
- SG-011 RFID HAL — **실제 하드웨어 구현은 범위 밖**. MockRfidReader 로 충분
- SG-002 `stub_engine.dart` 를 `engine_connection_provider` stubEngineBridge 에 실제 연결

**참조 SSOT**:
- `docs/2. Development/2.4 Command Center/APIs/RFID_HAL.md` (BS-04-04 operator)
- `docs/2. Development/2.4 Command Center/APIs/RFID_HAL_Interface.md` (N/A, SG-011 OUT_OF_SCOPE)
- `docs/2. Development/2.4 Command Center/Overlay/Engine_Dependency_Contract.md` (SG-002)
- `lib/features/command_center/providers/engine_connection_provider.dart`
- `lib/features/command_center/services/stub_engine.dart`

**금지**:
- Graphic Editor UI 재구현 (team1 소유, `rive` 프리뷰만 허용)
- `IRfidReader` 직접 인스턴스화 (Riverpod DI `rfidReaderProvider` 사용)

### Conductor (주기적 통합)

**역할**: 기획서 편집장 + 완결성 판정자 + 기획-프로토타입 추적 체계 관리자

**주기 작업**:
- `/team-merge` 로 팀 브랜치 main 통합
- `tools/spec_drift_check.py --all` 주간 실행 → `Spec_Gap_Registry.md` 업데이트
- `tools/reimplementability_audit.py` 주간 실행 → `Roadmap.md` 재판정
- 팀 간 계약 (`docs/2. Development/2.5 Shared/`) 소유 — 변경 시 decision_owner 알림
- Foundation/Roadmap/Spec_Gap_* 편집

**통합 테스트**:
- `integration-tests/*.http` 시나리오 유지
- 4팀 동시 기동 시 인계 가능 상태 확인

## 5. 이관 체크리스트

### 세션 시작 전
- [ ] `git pull origin main` 최신 커밋 (현재 `b0692ad`) 확보
- [ ] `python team2-backend/tools/init_db.py --force` (team2 세션 한정, fresh DB 필요 시)
- [ ] `python tools/spec_drift_check.py --all` baseline 확인
- [ ] MEMORY.md 최상위 전제 섹션 읽기 (🎯 프로젝트 의도)
- [ ] 해당 팀 CLAUDE.md 읽기 (브랜치 규칙 + 소유 경로)

### 작업 중
- [ ] SG-XXX 이슈 발견 시 `Conductor_Backlog/SG-*.md` 참조
- [ ] Type A/B/C/D 분류 먼저
- [ ] 코드 변경 → 계약 문서 동기화 (같은 커밋)
- [ ] 기존 TODO 마커 해소 시 주석 제거

### 커밋 전
- [ ] `pytest --co` (team2) / `dart analyze` (team3/team4) errors 0
- [ ] 해당 계약 drift scan 재실행
- [ ] Conventional Commit 메시지 (`feat(team{N})` / `fix(team{N})` / `docs(...)`)
- [ ] 팀 소유 외 파일 수정 시 커밋 메시지에 `notify: teamX` 표기

### Push 후
- [ ] pre-push hook 이 신규 drift 경고 없이 통과
- [ ] Conductor 세션이 주기적으로 `/team-merge` 로 main 통합

## 6. 안 해도 되는 것

- **SG-011 RFID 하드웨어 구현** — `out_of_scope_prototype: true`. 제조사 SDK 필요
- **MVP / Phase / 출시 일정** — 프로젝트 범위 밖 (기획서 완결 프로토타입)
- **모든 .md 에 frontmatter 부여** — 계약 문서만 대상
- **audit MISSING 수치 줄이기 위한 일괄 UNKNOWN** — 근거 없으면 금지

## 7. 긴급 대응

| 상황 | 대응 |
|------|------|
| 빌드/테스트 실패 | `Spec_Gap_Triage.md` Type 분류 → Type B/C 이면 기획 PR 우선 |
| hook blocking (cd team*/ 후) | 이미 절대경로화됨 (`${CLAUDE_PROJECT_DIR}`). 계속 blocking 이면 `settings.json` 재확인 |
| 팀 간 계약 충돌 | Conductor 세션에 에스컬레이션 (decision_owner 판정) |
| drift 급증 | 재scan 전후 commit diff 확인, 원인 팀 세션 알림 |

## 8. 관련 문서

| 파일 | 용도 |
|------|------|
| `CLAUDE.md` (root) | 최상위 전제 + Role + 프로토콜 요약 |
| `MEMORY.md` (~/.claude/projects/C--claude-ebs/memory/) | 프로젝트 의도 + feedback 규율 |
| `docs/4. Operations/Roadmap.md` | 챕터별 재구현 가능성 매트릭스 |
| `docs/4. Operations/Spec_Gap_Triage.md` | Type A/B/C/D 프로토콜 |
| `docs/4. Operations/Spec_Gap_Registry.md` | drift 집계 + SG 승격 index |
| `docs/4. Operations/Conductor_Backlog/SG-*.md` | 개별 spec gap 결정 기록 |
| `docs/4. Operations/Conductor_Backlog/IMPL-*.md` | 팀 구현 위임 지시 |
| `docs/2. Development/2.5 Shared/BS_Overview.md` | 용어·상태·FSM SSOT |
| `tools/spec_drift_check.py` | 7 계약 drift scanner |
| `tools/reimplementability_audit.py` | 재구현성 audit |
| `tools/validate_gfskin.py` | .gfskin 포맷 검증 |

---

**결론**: 구조적 재정비 완료. 이제 각 팀이 자기 SG·IMPL·TODO 마커를 개별 구현하면 된다. 기획서 완결성 80% + drift 4 계약 완전 PASS 수준에서 개발 재개.
