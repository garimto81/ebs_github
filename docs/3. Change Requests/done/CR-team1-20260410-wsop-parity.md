---
title: CR-team1-20260410-wsop-parity
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team1-20260410-wsop-parity
---

# CCR-DRAFT: WSOP LIVE Parity — EventFlightStatus/Restricted/BlindDetailType/Table 2축/Bit Flag RBAC

- **제안팀**: team1
- **제안일**: 2026-04-10
- **영향팀**: [team1, team2, team4]
- **변경 대상 파일**:
  - `contracts/specs/BS-02-lobby/BS-02-02-event-flight.md`
  - `contracts/specs/BS-02-lobby/BS-02-03-table.md`
  - `contracts/specs/BS-03-settings/BS-03-04-rules.md`
  - `contracts/specs/BS-01-auth/BS-01-02-rbac.md`
  - `contracts/data/DATA-02-entities.md`
- **변경 유형**: modify
- **변경 근거**: WSOP LIVE Confluence 미러(`C:\claude\wsoplive\docs\confluence-mirror\`) 원본 표준과의 parity 확보. Lobby/Settings UI 기획서에는 선반영 완료(UI-01 §9, UI-03 §1.1 및 Rules 탭 주석)했으나, 현재 `contracts/` 에는 대응 enum/필드가 없어 Team 1 은 mock 데이터로만 동작 가능한 상태. 본 CCR 로 5 개 영역의 계약 확장을 제안한다.

## 변경 요약

WSOP LIVE 프로덕션에서 실제 운영 중인 5 개의 규칙을 EBS contracts 에 반영한다.

1. **EventFlightStatus enum**: `Created=0 / Announce=1 / Registering=2 / Running=4 / Completed=5 / Canceled=6` (3 번은 skip). Event 와 Flight 가 공유.
2. **Flight.isRegisterable + dayIndex**: "Announce + Day2+" 조합을 `Restricted` 로 판정하기 위한 메타.
3. **BlindDetailType enum**: `Blind / Break / DinnerBreak / HalfBlind / HalfBreak` 5 타입. Flight 의 Blind 구조를 정확히 표현하기 위해 필요.
4. **Table 상태 2축 분리**: 기존 TableFSM(`EMPTY/SETUP/LIVE/PAUSED/CLOSED`) 은 유지하되, 직교 축으로 `isPause: bool` 필드 추가. "LIVE 이면서 일시정지(브레이크/카메라 리셋/중재)" 상태를 표현.
5. **Bit Flag Permission**: 현재 enum 문자열(`admin/operator/viewer`) 로 RBAC 를 체크하는 대신, `None=0 / Read=1 / Write=2 / Delete=4` 비트 플래그로 확장. 역할 → 리소스별 권한 매핑을 가능하게 한다.

## Diff 초안

### 1. `contracts/specs/BS-02-lobby/BS-02-02-event-flight.md`

```diff
 ## Event/Flight 상태

-Event 와 Flight 는 단순 문자열 상태(`active/pending/done`)를 가진다.
+Event 와 Flight 는 공통 enum `EventFlightStatus` 를 공유한다.
+
+```
+EventFlightStatus {
+  Created   = 0
+  Announce  = 1
+  Registering = 2
+  Running   = 4   // 3 은 WSOP LIVE 원본에서 skip
+  Completed = 5
+  Canceled  = 6
+}
+```
+
+Flight 는 추가로 다음 메타를 가진다:
+- `isRegisterable: bool` — 신규 등록 가능 여부
+- `dayIndex: int` — Event 내부 Day 순서 (0-based; Day1A=0, Day1B=0, Day2=1, ...)
+
+`is_restricted = (flight.status == Announce) && (flight.dayIndex >= 1)`
+— 이 조건을 만족하면 Lobby 에서 "Restricted" 배지로 표시한다.
```

### 2. `contracts/specs/BS-02-lobby/BS-02-03-table.md`

```diff
 ## Table 상태

 TableFSM: `EMPTY → SETUP → LIVE → PAUSED → CLOSED`
+
+추가로 `isPause: bool` 필드를 갖는다. 이는 GUI status 와 **직교하는 독립 축** 이다.
+
+| GUI status | isPause | 허용 | 의미 |
+|------------|:-------:|:----:|------|
+| LIVE | false | O | 정상 진행 |
+| LIVE | true | O | 진행 가능하나 일시정지(브레이크/중재) |
+| PAUSED | true | O | 운영자 명시적 중단 |
+| PAUSED | false | **거부** | 서버가 거부해야 하는 불변 조합 |
+| 그 외 | false | O | EMPTY/SETUP/CLOSED 에서는 isPause=false 고정 |
+
+Late Registration 타이머는 `isPause == true` 일 때 경과 시간 증가를 멈춘다.
```

### 3. `contracts/specs/BS-03-settings/BS-03-04-rules.md`

```diff
 ## Blind 구조

 Blind 레벨은 `BlindDetail` 배열로 표현되며, 각 항목은 타입을 갖는다.
+
+```
+BlindDetailType {
+  Blind      // 일반 블라인드 레벨 (SB/BB/Ante + duration)
+  Break      // 일반 휴식
+  DinnerBreak // 저녁 식사 휴식 (보통 60~75 분)
+  HalfBlind  // 기존 레벨의 절반 길이 (Late Reg 경계 조정)
+  HalfBreak  // 기존 break 의 절반 길이
+}
+```
+
+Late Registration 남은 시간 계산식:
+`late_reg_remaining = sum(level.duration for level in blindStructure
+                          if current_idx <= level.idx <= late_reg_end_idx)
+                      - elapsed_in_current_level`
+
+Break / DinnerBreak 도 duration 합산에 포함한다. HalfBlind / HalfBreak 는 절반 길이.
```

### 4. `contracts/specs/BS-01-auth/BS-01-02-rbac.md`

```diff
 ## 역할

 - Admin: 전체 권한
 - Operator: 할당 테이블 CC 만 write, 그 외 read
 - Viewer: 전체 read only
+
+## Permission Bit Flag
+
+문자열 역할 대신 **비트 플래그** 로 권한을 표현한다:
+
+```
+Permission {
+  None   = 0   // 0b0000
+  Read   = 1   // 0b0001
+  Write  = 2   // 0b0010
+  Delete = 4   // 0b0100
+}
+```
+
+역할 → 리소스별 권한 매핑 (대표 예시):
+
+| 리소스 | Admin | Operator (자기 할당) | Operator (타 테이블) | Viewer |
+|--------|:-----:|:--------------------:|:-------------------:|:------:|
+| Series/Event/Flight | 7 | 1 | 1 | 1 |
+| Table | 7 | 3 | 1 | 1 |
+| Seat/Player | 7 | 7 | 1 | 1 |
+| Settings (Rules/Outputs) | 7 | 3 | 1 | 1 |
+| Settings (GFX/Display) | 7 | 1 | 1 | 1 |
+
+클라이언트는 `role.permission & Permission.Write != 0` 같은 비트 연산으로 버튼 활성화를
+판단한다. 문자열 비교 금지.
```

### 5. `contracts/data/DATA-02-entities.md`

```diff
 ## Flight

 | 필드 | 타입 | 설명 |
 |------|------|------|
 | id | UUID | |
 | event_id | UUID | |
 | name | string | 예: "Day 1A" |
-| status | string | active/pending/done |
+| status | EventFlightStatus | enum (위 BS-02-02 참조) |
+| isRegisterable | bool | 신규 등록 허용 여부 |
+| dayIndex | int | Event 내부 Day 순서 (0-based) |
+| isPause | bool | Flight 단위 일시정지 (Late Reg 타이머 멈춤) |

 ## Table

 | 필드 | 타입 | 설명 |
 |------|------|------|
 | id | UUID | |
 | flight_id | UUID | |
 | status | TableStatus | EMPTY/SETUP/LIVE/PAUSED/CLOSED |
+| isPause | bool | LIVE/PAUSED 와 직교하는 일시정지 축 |
```

## 영향 분석

### Team 1 (Frontend, Quasar)

- UI-01 §9 WSOP LIVE Parity Notes 섹션으로 **선반영 완료** (본 critic revision). 계약 승격 후 mock 데이터를 실제 API 응답으로 교체.
- UI-03 §1.1 Ownership 소섹션 및 Rules 탭 주석으로 Blind / BlindDetailType 경계 선반영 완료.
- Quasar 컴포넌트에서 `is_restricted` 배지, `isPause` 아이콘, Bit Flag 권한 체크 헬퍼 유틸 추가 필요.
- 예상 작업: 약 1 일 분량 (선반영 덕분에 기획 재검토 없음).

### Team 2 (Backend, FastAPI)

- `GET /events/{id}/flights` 응답에 `status`(enum), `isRegisterable`, `dayIndex`, `isPause` 필드 추가.
- `GET /tables/{id}` / `GET /flights/{id}/tables` 응답에 `isPause` 필드 추가.
- `PUT /tables/{id}` 가 `PAUSED + isPause=false` 조합을 거부하도록 유효성 추가.
- `GET /auth/me` 또는 JWT payload 에 `permission: int` 비트 플래그 포함.
- `API-05 ws/lobby` 채널에서 Flight/Table 상태 변경 이벤트 페이로드 확장.
- SQLite/PostgreSQL 마이그레이션 필요: `flights` 테이블에 `is_registerable BOOL`, `day_index INT`, `is_pause BOOL` 컬럼 추가, `tables` 테이블에 `is_pause BOOL` 컬럼 추가.
- BlindDetailType enum 을 `blind_structures` 테이블 (또는 JSONB 컬럼) 에 반영.

### Team 4 (CC Flutter)

- CC 인스턴스가 `isPause` 필드를 구독/처리. Late Reg 타이머 일시정지 로직 연결.
- Bit Flag 권한 기반으로 CC 의 "자기 할당 테이블이 아닌 경우 read-only" UI 상태를 처리 (현재는 role 문자열 기반).
- BlindDetailType 5 타입을 CC 의 Blind 레벨 표시에 반영 (특히 HalfBlind / HalfBreak 의 절반 길이 렌더링).

### 마이그레이션 리스크

- `EventFlightStatus` 는 기존 문자열 `active/pending/done` 과 1:1 매핑되지 않는다. 마이그레이션 스크립트 필요:
  - `active` → `Running` (4)
  - `pending` → `Announce` (1) 또는 `Created` (0) — 시드 데이터 검토 필요
  - `done` → `Completed` (5)
- `isPause` 는 신규 필드이므로 default `false` 로 안전하게 추가 가능.
- Bit Flag Permission 은 기존 역할 문자열을 유지하면서 **부가 필드** 로 추가하는 방식 권장 (하위 호환).

## 대안 검토

1. **문자열 역할 유지**: 현재처럼 `admin/operator/viewer` 만 쓴다. **탈락** — 권한 세분화 요구(예: GFX 탭은 read only 지만 Rules 는 write 가능)를 커버 못 함.
2. **GraphQL 로 쿼리 단위 권한 체크**: Over-engineering. Phase 2+ 고려 사항.
3. **`isPause` 를 TableFSM 에 상태 전이로 흡수**: 상태 조합 폭발. `LIVE_PAUSED / PAUSED_CONFIRMED / ...` 등 구분 필요 → 비트 분리가 더 깨끗.
4. **`BlindDetailType` 을 클라이언트 로직으로 표현**: 계약에 없으면 CC/Lobby/Engine 이 각각 다른 방식으로 계산할 위험. SSOT 로 계약에 넣는 것이 정답.

## 검증 방법

### 단위

- Team 2: `pytest` — Flight status enum 시리얼라이저, `PAUSED + isPause=false` 거부 테스트, Permission 비트 연산 테스트.
- Team 1: Vitest — `is_restricted` 판정 헬퍼, Late Reg 계산식, Bit Flag 권한 체크 헬퍼.
- Team 4: Flutter 위젯 테스트 — `isPause` 아이콘 렌더링, BlindDetailType 5 타입 렌더링.

### 통합

- `integration-tests/` 에 HTTP/WS 시나리오 추가:
  - Announce + Day2 Flight 생성 → Lobby 에서 `Restricted` 배지 확인
  - Table 을 LIVE 상태로 둔 채 `isPause=true` 토글 → CC 에 WS 이벤트 도달 → Late Reg 타이머 멈춤
  - Operator 토큰으로 `GET /configs` 호출 → `permission & Read != 0` 확인, `PUT /configs` 는 GFX 탭에서 403

### 수동 회귀

- 기존 `active/pending/done` 상태의 시드 데이터가 마이그레이션 후 올바르게 `EventFlightStatus` 로 매핑되는지 Lobby 에서 눈으로 확인.
- WSOP LIVE 원본 스크린샷과 EBS Lobby 의 Flight 카드 상태 배지를 side-by-side 대조.

## 원본 출처 인용

WSOP LIVE Confluence 미러 (1,361 페이지) 에서 각 규칙을 확인:

- `C:\claude\wsoplive\docs\confluence-mirror\` 하위 `Tournament Management` 페이지 (EventFlightStatus enum, Restricted 규칙)
- `Blind Structure` 페이지 (BlindDetailType 5 타입, Late Reg 계산식)
- `RBAC & Permission Model` 페이지 (Bit Flag Permission)
- `Table Lifecycle` 페이지 (status + isPause 2 축 분리)

정확한 페이지 ID 는 Conductor 가 승격 시 본문에 기재한다 (draft 에서는 경로 인용만).

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 2 기술 검토 (마이그레이션 스크립트 / API 스키마)
- [ ] Team 4 기술 검토 (CC 의 isPause / BlindDetailType / Bit Flag 통합)
- [ ] Team 1 기술 검토 (본 CCR 제안팀 — 선반영 완료 확인)
