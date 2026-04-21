---
id: B-087
title: "Quasar → Flutter 이전 누락/drift 전수 수정 (master)"
status: PENDING
source: docs/4. Operations/Reports/2026-04-21-quasar-to-flutter-migration-audit.md
created: 2026-04-21
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

### B-087-1. Player UI 구현 결정 (P1)

- **현재**: `player_repository.dart` + `lobby/providers/player_provider.dart` 존재. UI 없음.
- **Quasar 원본**: `PlayerListPage.vue`, `PlayerDetailPage.vue`
- **결정 옵션**:
  - (a) Flutter 로 이식 (`features/lobby/screens/player_list_screen.dart` + `player_detail_screen.dart`) — Lobby 하위 sub-route 로 라우트 2개 추가
  - (b) "Lobby 하위 통합 완결" 선언 — Player 관리는 Lobby 대시보드 내 inline 확장 패널로만
- **의사결정 책임**: team1 (UI 기획 확인 후 team1 내부 결정)
- **관련 기획**: `Lobby/UI.md §Player 독립 레이어` 재확인 필요

### B-087-2. Engineering.md §6.4 WS dispatch 매핑 실측 정렬 + 네이밍 규약 결정 (P2)

- **drift**: 기획 5 이벤트 카테고리 vs 실측 25+ 이벤트 처리
- **규약 충돌**: `WebSocket_Events.md §1` 은 "PascalCase" 명시, `ws_dispatch.dart` 는 snake_case + dot-case 혼재
- **해결 경로**:
  1. team2 (WebSocket_Events publisher) 와 네이밍 규약 합의 — PascalCase 유지 or snake_case 공식화
  2. 결정된 규약으로 `ws_dispatch.dart` switch case 재작성 또는 `WebSocket_Events.md` 예시 재작성
  3. Engineering.md §6.4 테이블 실측 25+ 이벤트로 재작성
- **notify**: team2 (publisher)

### B-087-3. 누락 widget 이식 판정 (P2)

Quasar archive 대비 Flutter 미이식 widget 4건 — 필요성 판정 후 이식 or Backlog close:

| Quasar | Flutter 예상 경로 | 필요성 판정 |
|--------|-------------------|:-----------:|
| `common/WsDisconnectBanner.vue` | `foundation/widgets/ws_disconnect_banner.dart` | **필요** (관제 UX 필수) |
| `event/EventFormDialog.vue` | `features/lobby/widgets/event_form_dialog.dart` | Lobby 에서 Event 생성/수정 필요 시 필요 |
| `table/TableFormDialog.vue` | `features/lobby/widgets/table_form_dialog.dart` | Table 생성/수정 필요 시 필요 |
| `hand-history/HandDetail.vue` | `features/reports/widgets/hand_detail.dart` | Reports `hands-summary` 탭 상세 뷰 필요 |

### B-087-4. Repository 분리 재평가 (P2)

- **BlindStructureRepository 분리**: 현재 settings_repository 에 통합. UI (settings/blind_structure_screen.dart) 가 커지면 분리 필요. 현재 규모 OK → 유지 권고, 300+ 라인 넘으면 분리.
- **SeatRepository 분리**: TableRepository 에 통합된 seat* 메서드. `table_repository.dart` 가 300+ 라인 초과하면 분리 검토.

### B-087-5. SyncRepository 미이식 — 관찰 (P3)

- WSOP LIVE 폴링은 Backend (team2) 가 담당. Frontend 는 /api 소비만 해도 충분.
- Quasar `sync.ts` 의 Frontend 측 기능 중 필요한 것이 있는지 기획 재확인 필요.
- 필요 없으면 B-087-5 close.

## 수락 기준

- [ ] B-087-1 결정 확정 (옵션 a or b) + 해당 PR 병합
- [ ] B-087-2 team2 합의 + WebSocket_Events.md § 갱신
- [ ] B-087-3 4건 widget 판정 및 필요한 것 이식
- [ ] B-087-4 Repository 분리 재평가 결과 문서화
- [ ] B-087-5 필요성 판정

## 관련

- 선행 commit: `2cc13b1` (Flutter 단일 스택 확정), `a709b2f` (features 정렬)
- audit report: `docs/4. Operations/Reports/2026-04-21-quasar-to-flutter-migration-audit.md`
- 기획 SSOT: `docs/2. Development/2.1 Frontend/Engineering.md` §2.1, §4.3, §5.2
- 외부 의존: `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md` (team2)
