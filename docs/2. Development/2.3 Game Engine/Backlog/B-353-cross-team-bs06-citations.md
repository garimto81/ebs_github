---
id: B-353
title: "Cross-team BS-06-XX 인용 (101건) → 도메인 마스터 redirect 갱신 — 팀별 자율 처리 위임"
status: PENDING
priority: P2
created: 2026-04-28
parent: B-349 §6
related-prs:
  - "PR #7/#9/#12/#14 (4 도메인 마스터)"
  - "PR #19 (Deprecation shim)"
  - "PR (B-349 §3-5 cross-ref 보강 — 본 PR)"
ownership:
  - "team1 — Frontend docs 갱신 (Lobby/Overview.md 등)"
  - "team2 — Backend docs + 코드 갱신 (WebSocket_Events.md, enums.py 등)"
  - "team4 — Command Center docs + Flutter 코드 갱신 (RFID_HAL.md, *.dart 등)"
---

# [B-353] Cross-team BS-06-XX 인용 grep + redirect 갱신 (P2)

## 배경

도메인 마스터 통합 (PR #7/#9/#12/#14) 후 16 BS-06-XX 파일이 deprecation shim 으로 교체됨 (PR #19). 단, 다른 팀 (team1/2/4) 의 문서/코드에 BS-06-XX 인용이 **101 건** 잔존 — 이는 새 도메인 마스터 redirect 으로 갱신 필요.

본 Backlog 는 갱신 위치 카탈로그 + 팀별 책임 영역을 제시. 실제 갱신은 각 팀이 자율 처리 (cross-team governance — team3 가 다른 팀 영역을 직접 변경하지 않음).

## 인용 카탈로그

### 1. team1-frontend (3 건)

#### docs/2. Development/2.1 Frontend/

| 파일 | 인용 | redirect_to |
|------|------|-------------|
| `Lobby/Overview.md` (line 1100) | "22종 게임 (`BS-06-00-triggers.md` enum)" | Lifecycle 도메인 §2.6 event_game_type Enum + Variants 도메인 §2.1 25 게임 마스터 테이블 |
| `Backlog/_archived-2026-04/notify-ccr/NOTIFY-CCR-050-*.md` | "변경 대상: BS-06-00-triggers.md" | (archived 폴더 — 갱신 불필요, history 보존) |

### 2. team2-backend (8 건)

#### 코드 (2 건)

| 파일 | 인용 | redirect_to |
|------|------|-------------|
| `team2-backend/src/db/enums.py:34` | "Hand 상태 (game_phase) — BS_Overview §3.2 + BS-06-00-REF §1.9" | Lifecycle 도메인 §2.2 game_phase Enum |
| `team2-backend/src/db/enums.py:62` | "Hand 내 Player 상태 — BS_Overview §3.4 + BS-06-00-REF §1.5.2" | Lifecycle 도메인 §2.4 PlayerStatus Enum |

#### docs/2. Development/2.2 Backend/

| 파일 | 인용 | redirect_to |
|------|------|-------------|
| `APIs/WebSocket_Events.md:36` | "이벤트 소스 분류는 BS-06-00-triggers.md" | Triggers 도메인 §1.2 4 트리거 소스 + §3.7 Trigger 소스별 이벤트 분류 |
| `APIs/WebSocket_Events.md:711` | "BS-06-00-triggers.md §5.2 — CC 액션과 BO ConfigChanged 동시" | Triggers 도메인 §3.16.2 충돌 해결 |
| `APIs/WebSocket_Events.md:1143` | "최소 베팅 규칙 (BS-06-02 참조)" | Betting 도메인 §3.3~§3.5 매트릭스 1-3 |
| `Back_Office/Sync_Protocol.md:332` | "BS-06-00-triggers.md — BO 소스 이벤트 정의" | Triggers 도메인 §3.7.4 BO 소스 이벤트 14개 |
| `Database/ER_Diagram.md:23` | "Game Engine GameState/Player/Card/Pot 는 BS-06-00-REF Ch.2 정의" | Lifecycle 도메인 §5.1 GameState + §5.2 Player |
| `Database/State_Machines.md:133` | "상세: BS-06-01 시나리오 문서" | Lifecycle 도메인 §3.13 유저 스토리 16건 |
| `Database/State_Machines.md:260` | "event_flight_status enum — BS-06-00-REF 1.2.5" | (Overview.md §1.2.5 그대로 — lifecycle 발췌 외 영역) |

### 3. team4-cc (다수, ~80+ 건 추정)

#### 코드 (5 건)

| 파일 | 인용 | redirect_to |
|------|------|-------------|
| `team4-cc/src/lib/features/command_center/providers/engine_provider.dart:4` | "Maps to Team 3's GameState (BS-06-00-REF Ch.2)" | Lifecycle 도메인 §5.1 GameState |
| `team4-cc/src/lib/features/command_center/providers/hand_fsm_provider.dart:1` | "HandFSM StateNotifier — 9-state lifecycle (BS-05-01, BS-06-01)" | Lifecycle 도메인 §2.1 + §3.3 매트릭스 1 |
| `team4-cc/src/lib/models/enums/action_type.dart:1,3` | "Hand action types from BS-05-02 and BS-06-00-REF Ch.1" | Triggers 도메인 §1.7 ActionType Enum |
| `team4-cc/src/lib/models/enums/game_type.dart:1,3,17,24` | "BS-06-00-REF §1.1, 10 variants / Bet structure / Seat position" | Variants 도메인 §2.1 25 게임 마스터 + Lifecycle §2.5 game Enum |
| `team4-cc/src/test/providers/hand_fsm_test.dart:1` | "BS-05-01, BS-06-01 — 9-state lifecycle" | Lifecycle 도메인 §2.1 + §3.3 |

#### docs/2. Development/2.4 Command Center/

| 파일 | 인용 | redirect_to |
|------|------|-------------|
| `APIs/RFID_HAL.md:25` | "이벤트 합성은 BS-06-00-triggers.md §4" | Triggers 도메인 §2.7 Mock 모드 이벤트 합성 |
| `APIs/RFID_HAL_Interface.md:47` | "트리거 합성 규칙은 BS-06-00-triggers.md §4" | Triggers 도메인 §2.7 |
| `APIs/RFID_HAL_Interface.md:182` | "RFID 이벤트 카탈로그 BS-06-00-triggers.md §2.2" | Triggers 도메인 §3.7.2 RFID 소스 이벤트 6개 |
| `APIs/RFID_HAL_Interface.md:240` | "BS-06-00-triggers.md §3.2 — 폴드 인식" | Triggers 도메인 §3.15.2 |
| `APIs/RFID_HAL_Interface.md:538` | "BS-06-00-triggers.md §4.3 시나리오 스크립트" | Triggers 도메인 §2.7.3 시나리오 스크립트 재생 |
| `Command_Center_UI/Action_Buttons.md:22,212,284,320,412` | "BS-06-02-holdem-betting.md §X" | Betting 도메인 §3.5 매트릭스 3 + §5.5 CALL 강제 재계산 + §3.3 Matrix 1 + §4.1 액션별 거부 |
| `Command_Center_UI/Hand_Lifecycle.md` | (다수) | Lifecycle 도메인 §2.1 / §3.3 / §3.13 |
| `Command_Center_UI/Manual_Card_Input.md` | (다수) | Triggers 도메인 §3.15 + Variants 도메인 §3.16 |
| `Backlog/_archived-2026-04/notify-ccr/*.md` | "BS-06-00-triggers.md" | (archived — 갱신 불필요) |

## 갱신 권장 패턴

### 코드 주석 (단순 텍스트 replace)

원본 → 갱신 형태:

```dart
// Before
/// HandFSM StateNotifier — 9-state lifecycle (BS-05-01, BS-06-01).

// After
/// HandFSM StateNotifier — 9-state lifecycle.
/// 권위: docs/2. Development/2.3 Game Engine/Behavioral_Specs/Lifecycle_and_State_Machine.md
///       (구 BS-06-01, 2026-04-27 통합).
```

### 문서 인용 (cross-ref 추가)

원본 → 갱신 형태:

```markdown
<!-- Before -->
> 상세: BS-06-01 시나리오 문서 참조

<!-- After -->
> 상세: `docs/2. Development/2.3 Game Engine/Behavioral_Specs/Lifecycle_and_State_Machine.md` §3.13 유저 스토리 16건 (구 BS-06-01).
```

### Audit 도구 활용

`docs/_generated/legacy-id-redirect.json` 의 `mappings` 객체를 IDE 점프 / sed-like script 의 source-of-truth 로 활용:

```python
import json
mappings = json.loads(Path("docs/_generated/legacy-id-redirect.json").read_text())["mappings"]
# 각 BS-06-XX 인용을 mappings[id]["redirect_to"] 로 자동 갱신
```

## 분담 (Cross-team Governance)

| 담당 팀 | 갱신 범위 | 예상 PR 분량 |
|--------|---------|------------|
| **team1** | `docs/2. Development/2.1 Frontend/Lobby/Overview.md` 1건 + archived 무시 | S (1 PR, ~10 line) |
| **team2** | `team2-backend/src/db/enums.py` 2건 + `docs/2. Development/2.2 Backend/` 6건 = 8건 | M (1 PR, ~30 line) |
| **team4** | `team4-cc/src/` 코드 5건 + `docs/2. Development/2.4 Command Center/` ~75건 | L (3-4 PR 분할 권장) |
| **team3** (본 PR) | Backlog 카탈로그 등재 + legacy-id-redirect.json 보강 | (완료) |

## 수락 기준

- [x] cross-team 인용 grep 결과 카탈로그화 (본 Backlog)
- [x] `legacy-id-redirect.json` 에 mapping 보존 (PR #19 + 본 PR)
- [ ] team1 갱신 PR (별도 — 1건)
- [ ] team2 갱신 PR (별도 — 8건)
- [ ] team4 갱신 PR (별도 — 80+건, 3-4 PR 분할 권장)

## 관련

- B-349 §6 — 본 작업의 parent
- B-350 — API-04 정합 검증 (Triggers 도메인 §3.4.1)
- legacy-id-redirect.json — 매핑 권위 (audit 도구 + IDE 점프 source)
- PR #19 — 16 deprecation shim
- 4 도메인 마스터 PR (#7/#9/#12/#14)
