# 2026-04-10 CCR Batch — 팀별 영향 리포트

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | CCR-010~037 일괄 적용 후 각 팀 세션 개시용 요약 리포트 |

---

## 개요

2026-04-10 Conductor 세션에서 **28건의 CCR을 일괄 적용**했다 (5 skipped + 22 applied + 1 rejected). 이 리포트는 각 팀이 자기 세션에서 `git pull` 직후 읽고 구현을 시작할 수 있도록 **파일 수준 변경**과 **Action Items**를 팀별로 정리한 것이다.

### 전체 처리 요약

| 분류 | CCR | 설명 |
|------|-----|------|
| **SKIPPED** (5) | 010, 018, 019, 020, 021 | 이전 세션에서 이미 contracts/ 적용됨. 로그만 생성. |
| **APPLIED** (22) | 011~017, 022~036 | 실제 contracts/ 편집 수행 |
| **REJECTED** (1) | 037 | CCR-011에 의해 superseded (team4 bs08-graphic-editor-new) |

### 신규 생성 파일 18개

| 경로 | CCR |
|------|-----|
| `contracts/api/API-07-graphic-editor.md` | 013 |
| `contracts/data/DATA-07-gfskin-schema.md` | 012 |
| `contracts/specs/BS-01-auth/BS-01-02-rbac.md` | 017 |
| `contracts/specs/BS-02-lobby/BS-02-02-event-flight.md` | 017 |
| `contracts/specs/BS-02-lobby/BS-02-03-table.md` | 017 |
| `contracts/specs/BS-04-rfid/BS-04-05-register-screen.md` | 026 |
| `contracts/specs/BS-05-command-center/BS-05-07-statistics.md` | 027 |
| `contracts/specs/BS-05-command-center/BS-05-08-game-settings-modal.md` | 028 |
| `contracts/specs/BS-05-command-center/BS-05-09-player-edit-modal.md` | 028 |
| `contracts/specs/BS-05-command-center/BS-05-10-multi-table-ops.md` | 030 |
| `contracts/specs/BS-07-overlay/BS-07-05-audio.md` | 033 |
| `contracts/specs/BS-07-overlay/BS-07-06-layer-boundary.md` | 035 |
| `contracts/specs/BS-07-overlay/BS-07-07-security-delay.md` | 036 |
| `contracts/specs/BS-08-graphic-editor/BS-08-00-overview.md` | 011 |
| `contracts/specs/BS-08-graphic-editor/BS-08-01-import-flow.md` | 011 |
| `contracts/specs/BS-08-graphic-editor/BS-08-02-metadata-editing.md` | 011 |
| `contracts/specs/BS-08-graphic-editor/BS-08-03-activate-broadcast.md` | 011 |
| `contracts/specs/BS-08-graphic-editor/BS-08-04-rbac-guards.md` | 011 |

---

## Team 1 (Quasar Lobby) — 20 CCRs 참조

### 필수 참조 (신규 파일)

| 파일 | 용도 |
|------|------|
| `contracts/specs/BS-00-definitions.md` | §1 Lobby = Quasar 확정, §7.4 GE prefix (GEM/GEI/GEA/GER), Graphic Editor 정의 추가 |
| `contracts/specs/BS-01-auth/BS-01-02-rbac.md` 🆕 | Permission Bit Flag (Read=1, Write=2, Delete=4) — UI gate 판정 |
| `contracts/specs/BS-02-lobby/BS-02-02-event-flight.md` 🆕 | `EventFlightStatus` enum + `is_registerable`/`day_index`/`is_pause` |
| `contracts/specs/BS-02-lobby/BS-02-03-table.md` 🆕 | `is_pause` 직교 축 + TableFSM 조합 매트릭스 |
| `contracts/specs/BS-08-graphic-editor/BS-08-00-overview.md` 🆕 | **GE 신규 소유** — Lobby 탭 역할, 3-Zone UI, use cases |
| `contracts/specs/BS-08-graphic-editor/BS-08-01-import-flow.md` 🆕 | `.gfskin` 업로드 FSM, ajv-js 검증, rive-js 프리뷰 |
| `contracts/specs/BS-08-graphic-editor/BS-08-02-metadata-editing.md` 🆕 | GEM-01~25 편집 매트릭스, PATCH + ETag |
| `contracts/specs/BS-08-graphic-editor/BS-08-03-activate-broadcast.md` 🆕 | Activate FSM, GameState 경고, 멀티 CC 동기화 |
| `contracts/specs/BS-08-graphic-editor/BS-08-04-rbac-guards.md` 🆕 | Admin/Operator/Viewer UI gate |
| `contracts/data/DATA-07-gfskin-schema.md` 🆕 | `.gfskin` ZIP 포맷 + JSON Schema ($id: gfskin-1.0.json) |
| `contracts/api/API-07-graphic-editor.md` 🆕 | 8 엔드포인트 (Upload/List/Download/GetMetadata/PATCH/Activate/GetActive/Delete) |

### 수정된 기존 파일

| 파일 | 변경 섹션 | CCR |
|------|----------|-----|
| `contracts/specs/BS-00-definitions.md` | §1 앱 아키텍처 (Lobby → Quasar), §7.4 GE prefix | 011/014/016 |
| `contracts/specs/BS-03-settings/BS-03-02-gfx.md` | §6~§8 (Active Skin, Color Override, Action-Glow, Audio) | 025 |
| `contracts/specs/BS-03-settings/BS-03-04-rules.md` | §5 `BlindDetailType` enum + Late Reg 계산식 | 017 |
| `contracts/data/DATA-02-entities.md` | Flight/Table 필드 추가 (status enum, is_registerable, day_index, is_pause) | 017 |
| `contracts/api/API-01-backend-api.md` | `POST /tables/{id}/launch-cc` 응답에 launch_token, ws_url | 029 |

### 새 요구사항 (Team 1 구현 책임)

1. **Quasar 프로젝트 초기화** — `team1-frontend/src/` 현재 `.gitkeep`만. Quasar(Vue 3) + TypeScript 실제 초기화 필요 (B-068)
2. **GE 탭 신설** — `/lobby/graphic-editor` 라우트 + 3-Zone 레이아웃 (List / Preview / Actions)
3. **Rive 프리뷰** — `@rive-app/canvas` 통합, `.gfskin` ZIP → jszip 해제 → Rive 렌더
4. **JSON Schema 검증** — ajv-js로 `DATA-07 §2` 스키마 compile + validate
5. **ETag 기반 PATCH** — `If-Match` 헤더 추적, 412 충돌 다이얼로그
6. **Activate 플로우** — `X-Game-State` 헤더, GameState 경고 다이얼로그
7. **Bit Flag 권한** — `permission & Permission.Write !== 0` 패턴으로 UI gate
8. **BS-02/03 Enum 반영** — Flight status 정수 enum 표시, Restricted 배지, BlindDetailType별 스타일
9. **Tech Stack SSOT 동기화** — `team1-frontend/CLAUDE.md`에서 BS-00 §1을 SSOT로 참조

### Action Items

- [ ] B-068 Quasar 프로젝트 실제 초기화
- [ ] `team1-frontend/ui-design/UI-08-graphic-editor.md` 신규 작성 (GE 탭 UI 설계)
- [ ] `team1-frontend/qa/graphic-editor/` 디렉토리 신설 + QA 체크리스트
- [ ] `src/services/skinsApi.ts` — 8 엔드포인트 래퍼
- [ ] `src/stores/authStore.ts` — `permission` 정수 필드 + 비트 헬퍼 유틸
- [ ] `src/stores/ccrNoticesStore.ts` — `docs/backlog/team1.md` NOTIFY 처리
- [ ] `team1-frontend/CLAUDE.md` — BS-00 §1 SSOT 참조 명시

### Integration Test 시나리오 (Team 1 검증 대상)

- `integration-tests/scenarios/20-ge-upload-download.http` — Upload + Download
- `21-ge-patch-metadata-etag.http` — PATCH ETag
- `22-ge-activate-broadcast.http` — Activate + WS broadcast
- `23-ge-rbac-denied.http` — RBAC gate
- `10-auth-login-profile.http` — JWT 프로파일
- `60-event-flight-status-enum.http` — EventFlightStatus 전이
- `61-table-is-pause-constraint.http` — is_pause 제약
- `62-rbac-bit-flag.http` — Permission Bit Flag

### Blocker / 대기

- Team 2 API-07 구현 선행 필요 (Lobby는 클라이언트)
- Team 2 JWT AUTH_PROFILE 서버 구현 (현재 인증 후 테스트)

---

## Team 2 (FastAPI Backend) — 23 CCRs 참조

### 필수 참조 (신규 파일)

| 파일 | 용도 |
|------|------|
| `contracts/api/API-07-graphic-editor.md` 🆕 | **8 엔드포인트 신규 구현** — POST/GET/PATCH/PUT/DELETE |
| `contracts/data/DATA-07-gfskin-schema.md` 🆕 | 서버 측 `fastjsonschema`/`jsonschema` 검증 대상 |
| `contracts/specs/BS-01-auth/BS-01-02-rbac.md` 🆕 | Permission Bit Flag 서버 판정 로직 |
| `contracts/specs/BS-02-lobby/BS-02-02-event-flight.md` 🆕 | Flight status enum (TEXT → INTEGER) 마이그레이션 |
| `contracts/specs/BS-02-lobby/BS-02-03-table.md` 🆕 | PAUSED + is_pause=false 조합 거부 로직 |
| `contracts/specs/BS-08-graphic-editor/BS-08-03-activate-broadcast.md` 🆕 | `skin_updated` WS broadcast 구현 |

### 수정된 기존 파일 (Agent 1 선행 작업 유지)

| 파일 | 변경 | CCR |
|------|------|-----|
| `contracts/data/DATA-04-db-schema.md` | `idempotency_keys`/`audit_events` 테이블 | 018 |
| `contracts/api/API-01-backend-api.md` | Idempotency-Key, saga, launch_token, replay endpoint | 019/020/021/029 |
| `contracts/api/API-05-websocket-events.md` | seq, skin_updated, 직렬화 협상, WriteGameInfo | 015/021/023/024 |
| `contracts/api/API-06-auth-session.md` | AUTH_PROFILE, expires_at, refresh_expires_in | 010/019 |
| `contracts/specs/BS-01-auth/BS-01-auth.md` | §5.1~5.4 JWT 정책 | 010 |
| `contracts/specs/BS-05-command-center/BS-05-00-overview.md` | §7 Launch, §8 BO 복구, §9 FSM 경계 | 029/031 |

### 새 요구사항 (Team 2 구현 책임)

1. **API-07 구현** — 8 엔드포인트, `Skin` / `SkinVersion` / `active_skin_id` DB 모델
2. **Idempotency Store** — Redis 또는 DB 기반 key/value (TTL)
3. **ETag 발급/검증** — weak ETag (`W/"{version}-{hash}"`)
4. **WS skin_updated broadcast** — seq 단조증가, subscribe 중 CC/Overlay에 발행
5. **JWT AUTH_PROFILE** — 환경별 만료 시간, `auth_profile` 필드 반환
6. **Permission Bit Flag** — `require_permission(resource, Write)` dependency
7. **Flight status 마이그레이션** — TEXT → INTEGER alembic migration + 데이터 변환 (`active` → `Running(4)`, `pending` → `Announce(1)`, `done` → `Completed(5)`)
8. **Table is_pause 유효성** — PAUSED + is_pause=false 거부 (PUT /tables/{id})
9. **POST /tables/{id}/launch-cc** — `cc_session` record, `launch_token` JWT(5분), `cc_instance_id` 할당
10. **ReplayEvents 엔드포인트** — POST /tables/{id}/replay-events, Accept/PartialAccept/Reject 응답
11. **CC 서비스 계정** — `role: "cc_service"`, `.gfskin` 읽기 전용 토큰
12. **WriteGameInfo 핸들러** — 24 필드 검증 + GameInfoAck/GameInfoRejected
13. **MessagePack 지원** (Phase 2) — `?format=msgpack` 협상 (현재는 JSON만)
14. **Security Delay buffer** (Overlay 서비스 계층) — OutputEventBuffer

### Action Items

- [ ] `team2-backend/specs/impl/IMPL-05-graphic-editor.md` 신설 (API-07 구현 스펙)
- [ ] `team2-backend/specs/impl/IMPL-01-tech-stack.md` 갱신 — BS-00 §1 SSOT 참조로 변경 (이전 Next.js 잔재 제거)
- [ ] Alembic migration — Flight.status INTEGER 변환
- [ ] Alembic migration — `skins`, `skin_versions` 테이블
- [ ] Alembic migration — `idempotency_keys`, `audit_events` 테이블 (Agent 1 작업 후속)
- [ ] `routers/skins.py` 신규 (8 엔드포인트)
- [ ] `routers/tables.py` 확장 — `/launch-cc`, `/replay-events`, `/rebalance`
- [ ] `services/websocket_hub.py` — `skin_updated` broadcast + seq 단조증가
- [ ] `services/auth_profile.py` — 환경별 JWT 발급
- [ ] `dependencies/rbac.py` — Permission Bit Flag 판정
- [ ] `team2-backend/CLAUDE.md` — BS-00 §1 SSOT 참조 명시

### Integration Test 시나리오

- `10-auth-login-profile.http`, `11-idempotency-key.http`, `12-table-rebalance-saga.http`, `13-ws-event-seq-replay.http`
- `20~23-ge-*.http` (4개)
- `30-cc-launch-flow.http`, `31-cc-bo-reconnect-replay.http`, `32-cc-write-game-info.http`
- `40-overlay-security-delay.http`, `50-rfid-deck-register.http`
- `60~62-*.http` (3개)

### Blocker / 대기

- 없음 (서버는 대부분 blocker 없이 착수 가능)

---

## Team 3 (Game Engine) — 4 CCRs 참조

### 필수 참조

| 파일 | 용도 | CCR |
|------|------|-----|
| `contracts/api/API-03-rfid-hal-interface.md` | §9~§13 신규 (UART 생명주기, 안테나 튜닝, 펌웨어 감지, 다중 리더, ST25R3916 마이그레이션) | 022 |
| `contracts/api/API-05-websocket-events.md §9` | `WriteGameInfo` 24 필드 스키마 — Engine 수신 + 검증 | 024 |
| `contracts/specs/BS-07-overlay/BS-07-05-audio.md` 🆕 | 오디오 레이어 — Engine이 발행할 오디오 이벤트(`CardDealt`, `PlayerAllIn` 등) | 033 |
| `contracts/specs/BS-07-overlay/BS-07-06-layer-boundary.md` 🆕 | Layer 1 자동화 정도 (완전 자동 vs 반자동) | 035 |

### 수정된 기존 파일

| 파일 | 변경 |
|------|------|
| `contracts/specs/BS-05-command-center/BS-05-01-hand-lifecycle.md` | RFID 완료 시 자동 스트리트 전이 + Run It Multiple 예외 (W12 해소) |

### 새 요구사항 (Team 3 구현 책임)

1. **HAL 생명주기 FSM** — `DISCONNECTED/CONNECTING/CONNECTED/CONNECTION_FAILED/RECONNECTING`
2. **재연결 정책** — `[0ms, 5s, 10s × 100]` 백오프
3. **안테나 튜닝 재시도** — 3회 재시도 + degraded/failed 상태
4. **펌웨어 버전 감지** — `HandshakeComplete` 이벤트 + 지원/권장/legacy 판정
5. **Mock 시뮬레이션 API** — `injectDisconnect/injectReconnect/simulateHandshakeFailure`
6. **WriteGameInfo 수신** — 24 필드 검증 후 HandFSM IDLE → SETUP_HAND 전이
7. **자동 스트리트 전이** — 보드 RFID 감지 → Engine이 FLOP/TURN/RIVER 자동 전이 (Run It Multiple은 예외)
8. **오디오 이벤트 발행** — `CardDealt`, `PlayerFold/Bet/AllIn`, `WinnerRevealed`, `ActionClock≤10s` 등

### Action Items

- [ ] `team3-engine/specs/engine-spec/BS-06-01-holdem-lifecycle.md` — 자동 스트리트 전이 섹션 추가 (CCR-031 후속)
- [ ] `team3-engine/ebs_game_engine/lib/hal/reader_state.dart` 신규 — FSM 구현
- [ ] `team3-engine/ebs_game_engine/lib/hal/reader_reconnect_policy.dart` — 재연결 백오프
- [ ] `team3-engine/ebs_game_engine/lib/hal/antenna_tuning.dart` — 튜닝 재시도
- [ ] `team3-engine/ebs_game_engine/lib/protocol/write_game_info.dart` — 24 필드 검증
- [ ] `team3-engine/ebs_game_engine/lib/events/audio_events.dart` — 오디오 이벤트 정의

### Integration Test 시나리오

- HAL 테스트는 `.http`로 불가 — `team3-engine/test/integration/hal_reconnect_test.dart` 직접 작성 필요
- `32-cc-write-game-info.http` — WriteGameInfo는 WebSocket 수동 검증 절차 포함

### Blocker / 대기

- Team 2 WebSocket hub 기반 구조 (Team 3 Engine이 publish할 경로)

---

## Team 4 (CC + Overlay) — 24 CCRs 참조

### ⚠ 최우선 Action (CCR-011 후속)

**Team 4 `CLAUDE.md` 수정 필요** — CCR-037 REJECT + CCR-011 결정에 따라 Team 4의 역할이 축소됐다. Graphic Editor는 **Team 1 소유**로 이관됐으므로:

- [ ] **`team4-cc/CLAUDE.md`** 에서 `## 3개 화면` 섹션을 `## 2개 화면`으로 수정:
  - ❌ 제거: `Graphic Editor` 행 (Skin/Overlay 시각 편집)
  - ✅ 유지: `Command Center`, `Overlay`
  - 추가: `Skin Consumer` 역할 명시 (`skin_updated` WS 수신 + BS-07-03 §5 로드 FSM)
- [ ] **`team4-cc/ui-design/reference/skin-editor/`** → **`archive/skin-editor-nextjs-abandoned/`** 로 이동
- [ ] **`team4-cc/ui-design/reference/action-tracker/`** 는 유지 (BS-05 AT 화면 체계의 reference)

### 필수 참조 (신규 파일 — Team 4 구현 주 대상)

| 파일 | 용도 |
|------|------|
| `contracts/specs/BS-04-rfid/BS-04-05-register-screen.md` 🆕 | AT-05 RFID Register UI + 54장 등록 FSM |
| `contracts/specs/BS-05-command-center/BS-05-07-statistics.md` 🆕 | AT-04 Statistics 화면 |
| `contracts/specs/BS-05-command-center/BS-05-08-game-settings-modal.md` 🆕 | AT-06 Game Settings 모달 |
| `contracts/specs/BS-05-command-center/BS-05-09-player-edit-modal.md` 🆕 | AT-07 Player Edit 모달 + Sitting Out 정책 |
| `contracts/specs/BS-05-command-center/BS-05-10-multi-table-ops.md` 🆕 | 다중 테이블 운영 패턴 A/B/C + 키보드 포커스 |
| `contracts/specs/BS-07-overlay/BS-07-05-audio.md` 🆕 | **Multi-channel AudioPlayer 구현** (1 BGM + 2 Effect + Temp) |
| `contracts/specs/BS-07-overlay/BS-07-06-layer-boundary.md` 🆕 | Layer 1 책임 + Layer 2/3 위임 경계 |
| `contracts/specs/BS-07-overlay/BS-07-07-security-delay.md` 🆕 | **이중 출력 (Backstage/Broadcast) buffer 구현** |

### 수정된 기존 파일 (전면 확장)

| 파일 | 변경 섹션 | CCR |
|------|----------|-----|
| `contracts/specs/BS-05-command-center/BS-05-00-overview.md` | §6 AT 카탈로그, §7 Launch, §8 BO 복구, §9 FSM 경계, §10 운영 패턴 | 027/028/029/030/031 |
| `contracts/specs/BS-05-command-center/BS-05-01-hand-lifecycle.md` | RFID 자동 스트리트 전이 | 031 |
| `contracts/specs/BS-05-command-center/BS-05-02-action-buttons.md` | NEW HAND의 `WriteGameInfo` 프로토콜 연결 | 024/031 |
| `contracts/specs/BS-05-command-center/BS-05-03-seat-management.md` | §6 시각 규격 (포지션 마커, 좌석 배경, action-glow) | 032 |
| `contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md` | §6 카드 슬롯 5상태 FSM + AT-03 모달 | 028/032 |
| `contracts/specs/BS-04-rfid/BS-04-01-deck-registration.md` | AT-05 참조 이관 | 026 |
| `contracts/specs/BS-07-overlay/BS-07-00-overview.md` | §4 Layer 경계 + BS-07-06 참조 | 035 |
| `contracts/specs/BS-07-overlay/BS-07-01-elements.md` | Player Element 시각 규격 (CC와 동일 색상) | 034 |
| `contracts/specs/BS-07-overlay/BS-07-02-animations.md` | Rive 사운드 경계 + CC-Overlay 일관성 | 033/034 |
| `contracts/specs/BS-07-overlay/BS-07-04-scene-schema.md` | `player_state_colors` 필드 | 034 |

### 새 요구사항 (Team 4 구현 책임)

1. **AT 화면 체계 8개 (AT-00~07)** — Login/Main/ActionView/CardSelector/Statistics/RFIDRegister/GameSettings/PlayerEdit
2. **AT-01 7 Zone 레이아웃 (M-01~07)** — Toolbar/InfoBar/라벨/Straddle/카드/블라인드/액션
3. **카드 슬롯 5상태 FSM** — EMPTY/DETECTING/DEALT/FALLBACK/WRONG_CARD
4. **WriteGameInfo 발행** — NEW HAND 버튼 → 24 필드 프로토콜
5. **BO 연결 복구** — 30s 하트비트, 로컬 Event Sourcing (20 이벤트), ReplayEvents
6. **다중 테이블 운영** — Pattern A/B/C, 키보드 포커스 가드
7. **시각 규격 준수** — 포지션 마커 색상, 좌석 배경, action-glow 0.8s
8. **Overlay 오디오 레이어** — `AudioPlayerProvider` (Riverpod), 1 BGM + 2 Effect + Temp
9. **Rive 사운드 경계** — State Machine Input 리스너 + AudioPlayer 라우팅
10. **Security Delay 이중 출력** — Backstage(즉시) + Broadcast(delay) NDI 채널
11. **Skin Consumer** — `skin_updated` WS 수신 → `.gfskin` 다운로드 → in-memory 해제 → Rive 리렌더
12. **RFID Register 화면** — 54장 등록 UI (4×13 그리드 + Joker 2)

### Action Items

- [ ] **`team4-cc/CLAUDE.md` 수정** (최우선, CCR-011 후속)
- [ ] `team4-cc/ui-design/reference/skin-editor/` → archive 이동
- [ ] `team4-cc/src/lib/features/command_center/` — AT-00~07 화면 구조
- [ ] `team4-cc/src/lib/features/rfid_register/` — AT-05 모듈
- [ ] `team4-cc/src/lib/features/overlay/audio/` — AudioPlayerProvider
- [ ] `team4-cc/src/lib/features/overlay/security_delay/` — OutputEventBuffer
- [ ] `team4-cc/src/lib/core/fsm/card_slot_fsm.dart` — 5상태 FSM
- [ ] `team4-cc/src/lib/core/protocol/write_game_info.dart` — 24 필드 직렬화
- [ ] `team4-cc/src/lib/core/session/bo_reconnect.dart` — 재연결 + ReplayEvents
- [ ] `team4-cc/src/lib/core/sync/skin_consumer.dart` — `skin_updated` 핸들러
- [ ] `team4-cc/qa/command-center/` — AT-00~07 QA 체크리스트 (수동 시각 검증)
- [ ] `team4-cc/qa/audio/` — Audio 재생 QA
- [ ] `team4-cc/CLAUDE.md` — BS-00 §1 SSOT 참조 + 2개 화면 구조

### Integration Test 시나리오

- `30-cc-launch-flow.http`, `31-cc-bo-reconnect-replay.http`, `32-cc-write-game-info.http`
- `40-overlay-security-delay.http`
- `50-rfid-deck-register.http`
- WebSocket 수동 검증 절차 포함 (wscat)
- 수동 QA (CCR-028/030/032/033/034) — `team4-cc/qa/` 체크리스트 작성 필요

### Blocker / 대기

- Team 1 GE 허브 완성 (skin_updated 발신 측) — Skin Consumer 테스트 의존
- Team 2 API-07 구현 (`.gfskin` 다운로드 엔드포인트) — CC Skin Consumer 의존

---

## Team 3/4 HAL 및 UI 수동 QA 대상 (integration-tests 범위 밖)

| 영역 | CCR | 수동 검증 위치 |
|------|-----|--------------|
| RFID UART FSM | 022 | `team3-engine/qa/hal/` |
| 안테나 튜닝 재시도 | 022 | 물리 테스트 |
| AT 화면 체계 (8화면) | 028 | `team4-cc/qa/command-center/` |
| 다중 테이블 운영 패턴 | 030 | OS 레벨 수동 |
| 시각 규격 일관성 | 032/034 | `team4-cc/qa/visual/` |
| Audio 재생 | 033 | `team4-cc/qa/audio/` |

---

## 공통 작업 (모든 팀)

### docs/backlog/team{N}.md NOTIFY 처리

각 팀은 자기 `docs/backlog/team{N}.md` 에서 다음 2종류의 NOTIFY를 만난다:

1. **`[NOTIFY-CCR-NNN]`** (current, 2026-04-10 batch) — 이 리포트의 "영향 CCRs" 목록과 일치. 각 CCR의 promoting 로그 + 본 리포트 참조.
2. **`[NOTIFY-LEGACY-CCR-NNN] [LEGACY]`** — 이전 세션 잔재, **내용 무시 가능**. 제목에 `[LEGACY]` 경고 배지와 블록 상단에 `⚠ **LEGACY NOTIFY**` 주석이 있다. 추적용으로 보존되지만 실제 구현 대상은 아니다.

### Stale CCR 번호 중복 주의

이번 batch에서 CCR-010~025 번호 중 일부(010, 011, 015, 016 등)는 **이전 세션과 의미가 다른** 현재 CCR이다. 팀 세션에서 NOTIFY-CCR-010을 볼 때 반드시 **promoting/의 실제 제목** 또는 본 리포트의 "영향 CCRs" 목록을 기준으로 판단한다.

---

## 로컬 상태 조회 명령

각 팀 세션에서 작업 시작 시 다음을 수행:

```bash
# 1. 최신 pull
git pull feat/bo

# 2. 자기 팀 영향 파일 리스트 확인 (본 리포트에서 복사)

# 3. promoting 로그 스캔
grep -l "제안팀.*team1" docs/05-plans/ccr-inbox/promoting/CCR-*.md  # team1 제안
grep -l "영향팀.*team1" docs/05-plans/ccr-inbox/promoting/CCR-*.md  # team1 영향

# 4. 개인 backlog 확인
cat docs/backlog/team1.md  # 자기 팀 파일

# 5. Integration test 시나리오 해당 번호 실행
code integration-tests/scenarios/20-ge-upload-download.http
```

---

## 참조

- `docs/05-plans/ccr-inbox/promoting/CCR-010~037` — 각 CCR의 적용 로그 (원본 draft 링크 포함)
- `docs/05-plans/ccr-inbox/archived/CCR-DRAFT-*` — 원본 draft (team3-wsop-conformance 포함)
- `integration-tests/scenarios/README.md` — 시나리오 카탈로그
- `integration-tests/scenarios/_TODO.md` — 미작성 시나리오 + 수동 검증 항목
- `CLAUDE.md §계약 관리` — CCR 프로세스 정의 (v3 배치 모드)
- `docs/backlog/_aggregate.md` — 전체 팀 backlog 집계
