---
id: B-087
title: "Quasar → Flutter 이전 누락/drift 전수 수정 (master)"
status: IN_PROGRESS
source: docs/4. Operations/Reports/2026-04-21-quasar-to-flutter-migration-audit.md
created: 2026-04-21
updated: 2026-04-21
owner: team1
---

# B-087 — Quasar → Flutter 이전 drift master 항목

## 배경

2026-04-21 `/team` 수행 결과 Quasar 아카이브 (`_archive-quasar/src-late/`) vs Flutter `lib/` + 기획 SSOT (`docs/2. Development/2.1 Frontend/Engineering.md`) 간 **45+ drift** 발견. 전수 감사 보고서 작성 완료:

**감사 보고서**: `docs/4. Operations/Reports/2026-04-21-quasar-to-flutter-migration-audit.md`

## 본 commit 에서 해결된 항목 (closed)

- [x] Engineering.md §2.1 디렉토리 구조 → 2026-04-21 실측 재작성
- [x] Engineering.md §4.3 라우트 table → 9 routes 실측 재작성
- [x] Engineering.md §5.2 Repository 매핑 → 14 classes 실측 재작성 + SeatRepository/BlindStructureRepository 통합 명시

## PENDING 후속 항목 (sub-tasks)

### B-087-1. Player 독립 화면 구현 — ✅ DONE (2026-04-21)

**결정**: `Lobby/UI.md §화면 4 Player (독립 레이어)` 명시 준수 — **옵션 (a) 신규 구현** 채택. 단 detail 은 **dialog** (별도 라우트 없음, 기획 line 943 준수).

**구현**:
- `features/players/screens/players_screen.dart` (신규 feature 디렉토리) — DataTable (Name/Table/Seat/Stack/Status/Actions) + 검색 + Status filter (All/Active/Waiting/Busted) + Add Player placeholder
- `features/players/widgets/player_detail_dialog.dart` — 행 클릭 시 읽기 전용 상세 다이얼로그
- `lib/features/lobby/providers/player_provider.dart` 재사용 (cross-feature import 허용)

**라우팅**:
- `/players` 라우트 추가 (`app_router.dart`)
- NavigationRail 에 Players 엔트리 추가 (6개 → 7개, Lobby/Players/Staff/Settings/GFX/Reports)

**문서 동기화**:
- `team1/CLAUDE.md §아키텍처` features 6 → 7 (+players)
- `Engineering.md §2.1` + `§4.3` 동기화 (route 9 → 10)
- `INDEX.md` features 7 반영

**잔여 후속**:
- Player 등록/수정/삭제 dialog (Add Player 버튼) — `B-F005` 로 분리
- 좌석 이동/제거 actions — 후속 스토리

### B-087-2. WS 이벤트 네이밍 규약 정렬 — **규약 확정 DONE, 마이그레이션 PENDING** (2026-04-21)

- **drift 원인 (확인)**: WSOP LIVE 원본 규약 은 SignalR **PascalCase** (`SeatInfo`). EBS `WebSocket_Events.md line 329` 의 snake_case divergence 주석 은 **근거 없는 임의 divergence** (원칙 1 위반).
- **확정 규약 (2026-04-21)**: WS event type = **PascalCase** — WSOP LIVE 직접 준수. 상세는 `docs/2. Development/2.5 Shared/Naming_Conventions.md §2` (신규 SSOT).
- **본 commit 완료**:
  - [x] `Naming_Conventions.md` SSOT 신규 작성 (Shared, Conductor 영역 — notify conductor)
  - [x] WSOP LIVE 규약 전수 조사 (SignalR hub naming, JSON field, REST path)
- **PENDING (별건 PR 체인)**:
  - [ ] PR-1 (Conductor): `WebSocket_Events.md line 329` divergence 주석 정정 + `BS_Overview.md §이벤트 네이밍` Naming_Conventions.md pointer 로 축약
  - [ ] PR-2 (team2): publisher backend snake_case 10개 이벤트 → PascalCase migrate (`clock_tick` → `ClockTick` 등)
  - [ ] PR-3 (team1): `ws_dispatch.dart` 26 switch case PascalCase 통일 + dot.case 제거 + 중복 case 통합
  - [ ] PR-4 (team4): CC consumer 동일 적용
  - [ ] PR-5 (Conductor): `tools/ws_naming_check.py` + CI gate (재발 방지)
- **notify**: conductor (PR-1, PR-5), team2 (PR-2), team4 (PR-4)

### B-087-3. 누락 widget 이식 판정 — ✅ DONE (2026-04-21)

**감사 정정**: audit 원본에서 3건을 "미이식" 으로 판정했으나 실측 재확인 결과 commit `70d6d7a` (2026-04-16 Flutter 전면 전환) 에 이미 포함되어 있었음. audit 스크립트의 false positive. 1건만 실제 미이식 → 신규 작성.

| Quasar | Flutter 경로 | 상태 | 라인 수 |
|--------|--------------|:----:|:------:|
| `common/WsDisconnectBanner.vue` | `foundation/widgets/ws_disconnect_banner.dart` | ✅ 기존 (70d6d7a) | 27 |
| `event/EventFormDialog.vue` | `features/lobby/widgets/event_form_dialog.dart` | ✅ 기존 (70d6d7a) | 606 |
| `table/TableFormDialog.vue` | `features/lobby/widgets/table_form_dialog.dart` | ✅ 기존 (70d6d7a) | 215 |
| **`hand-history/HandDetail.vue`** | **`features/reports/widgets/hand_detail.dart`** | **✨ 신규 작성** | 227 |

audit 보고서 `docs/4. Operations/Reports/2026-04-21-quasar-to-flutter-migration-audit.md` §2.2 의 3건 false positive 는 별도 correction 섹션에 기록.

### B-087-4. Repository 분리 재평가 — ✅ CLOSE (유지 권고)

**판정**: 현재 통합 구조 유지. 분리 트리거는 파일 라인 수 300+ 초과 시점 (table_repository.dart / settings_repository.dart 모니터링). 선제 분리 불필요.

| Repository | 통합 위치 | 현재 라인 수 | 분리 트리거 | 판정 |
|------------|-----------|:------------:|:-----------:|:----:|
| `BlindStructureRepository` | `settings_repository.dart` | < 300 | 300+ 초과 시 | **유지** |
| `SeatRepository` | `table_repository.dart` | < 300 | 300+ 초과 시 | **유지** |

분리 트리거 발동 시 재평가. 지금은 단일 파일이 기능 맥락 (table + seat, settings + blind) 을 응집 보유하는 게 가독성 우수.

### B-087-5. SyncRepository 미이식 — ✅ CLOSE (불필요)

**판정**: Frontend 측 SyncRepository 불필요. WSOP LIVE 폴링은 Backend (team2) `BO-02 Sync Protocol` 에 따라 전담. Lobby 는 cache 된 결과를 `/api/v1/{series,events,flights}` 로 소비하면 충분 (`source: "api" | "manual"` 필드로 출처 식별). Quasar `sync.ts` 의 Frontend 측 manual sync trigger 기능은 현재 기획에 없음.

필요 시점 재활성화 조건: Lobby 에서 수동 "WSOP LIVE Resync" 버튼 요구사항 공식 기획 확정 시.

## 수락 기준

- [x] B-087-1 결정 확정 (옵션 a or b) + 해당 PR 병합 — **DONE** (옵션 a — Lobby/UI.md §독립 레이어 준수하여 신규 구현)
- [x] B-087-2 규약 확정 + Naming_Conventions.md SSOT 확립 — **DONE** (WSOP LIVE PascalCase 직접 준수). PR-1~5 코드 마이그레이션 은 별건
- [x] B-087-3 4건 widget 판정 및 필요한 것 이식 — **DONE** (3 false positive + hand_detail.dart 신규)
- [x] B-087-4 Repository 분리 재평가 결과 문서화 — **CLOSE** (유지 권고)
- [x] B-087-5 필요성 판정 — **CLOSE** (불필요)

## 관련

- 선행 commit: `2cc13b1` (Flutter 단일 스택 확정), `a709b2f` (features 정렬)
- audit report: `docs/4. Operations/Reports/2026-04-21-quasar-to-flutter-migration-audit.md`
- 기획 SSOT: `docs/2. Development/2.1 Frontend/Engineering.md` §2.1, §4.3, §5.2
- 외부 의존: `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md` (team2)
