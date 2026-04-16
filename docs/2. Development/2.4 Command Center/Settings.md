---
title: Settings
owner: team4
tier: internal
legacy-id: BS-03
last-updated: 2026-04-16
---

# BS-03 Settings — Command Center 설정 행동 명세

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-15 | 신규 작성 (G4-B) | WSOP LIVE Series/Event/Table 스코프 정렬을 위해 Settings 전용 문서 분리 |
| 2026-04-16 | Rules 탭 통합 | 구 AT-06 Game Settings Modal 필드를 Rules 탭으로 흡수. AT-06 독립 모달 → Table Settings Rules 탭 재정의 |

---

## 개요

Command Center 에서 오버레이 렌더·출력·게임 규칙을 제어하는 **설정값**의 조회/변경/적용 흐름을 정의한다. 2026-04-15 G4-B 재작성 전에는 "글로벌 단일 세트" 였으나, **WSOP LIVE 와 동일하게 Series/Event/Table 3단 스코프 + global fallback** 로 복구했다 (CLAUDE.md 원칙 1 정렬).

> 참조: `../2.2 Backend/Back_Office/Overview.md §3.6`, `../2.2 Backend/Database/Schema.md §configs`, `../2.2 Backend/APIs/WebSocket_Events.md §5.1 ConfigChanged payload`

---

## 스코프 모델

### 4단 스코프 + override 체인

| 스코프 | scope_id | 의미 |
|:------:|:--------:|------|
| `global` | NULL | 전체 기본값 (방송 운영 전사 공통) |
| `series` | series.series_id | 시즌 단위 (WSOP 2026 전체) |
| `event` | events.event_id | 개별 이벤트 (Main Event 등) |
| `table` | tables.table_id | 테이블 단위 (Feature Table 등 특수 설정) |

**해결 순서** (BO `resolve_config(key, table_id)`):
```
table(table_id)
  └─ 없으면 → event(table.event_flight_id.event_id)
     └─ 없으면 → series(event.series_id)
        └─ 없으면 → global
           └─ 없으면 → default value
```

**예**: Feature Table 용 특수 오버레이 스킨을 `table(42, key=overlay.skin_id)` 에 저장 → 해당 테이블만 특수 스킨, 나머지는 event→series→global 로 fallback.

### 저장 스키마

`configs` 테이블 (Schema.md §configs, 2026-04-15 G4-C 확장):
```
UNIQUE(key, scope, scope_id)
CHECK(scope IN ('global','series','event','table'))
CHECK((scope='global' AND scope_id IS NULL) OR (scope!='global' AND scope_id IS NOT NULL))
```

---

## 6탭 × 기본 스코프

| 탭 | 주요 항목 | 기본 스코프 | 이유 |
|----|----------|:----------:|------|
| **Outputs** | NDI/HDMI 라우팅, 해상도, 프레임레이트 | `event` | 이벤트마다 송출 목적지 달라짐 (Feature Table 전용 채널 등) |
| **GFX** | 스킨, 로고, 자막 스타일 | `series` | 시즌 브랜딩 단위. 개별 이벤트 override 가능 |
| **Display** | 보안 딜레이, 그래픽 레이어 on/off | `event` | 규정상 이벤트별 딜레이 설정 (Main Event 30초 등) |
| **Rules** | 게임 유형, 블라인드, 앤티, 스트래들, cap, 변형 규칙 | `event` | 이벤트 자체 특성. 상세: §Rules 탭 상세 |
| **Stats** | 통계 표시 범위 (핸드 최근 N개 등) | `table` | 테이블별 하이라이트 다름 |
| **Preferences** | 오퍼레이터 단축키, UI 선호 | `global` | 전사 기본값, 유저 단위 override 는 별도 `user_preferences` 로 분리 |

> 위 기본값은 **UI 에서 변경 가능한 scope 의 초기 진입점** 이다. 실제 저장 시 사용자가 더 좁은(또는 넓은) scope 로 변경할 수 있다.

---

## 진입 경로 (UI)

### 이전 (2026-04-09 ~ 2026-04-14): 글로벌 단독 진입 — **폐기**

> ⚠ Lobby 헤더 `[⚙]` 버튼 → 전역 Settings 모달 — 이 경로는 **G4-B 에서 제거**. 테이블/이벤트 구분 없이 모든 CC 에 동일 값이 반영되어 WSOP LIVE 정렬에 위배됐음.

### 현재 (2026-04-15 ~): Context 기반 진입

1. **Global Settings** (전사 기본값 편집)
   - 진입: Lobby 헤더 `[⚙]` → "Global Settings"
   - 권한: Admin 전용
   - 저장: `configs(scope='global', scope_id=NULL)`

2. **Series Settings**
   - 진입: Lobby Series 목록 → 시즌 우클릭 → "Series Settings"
   - 권한: Admin / Operator
   - 저장: `configs(scope='series', scope_id=<series_id>)`

3. **Event Settings**
   - 진입: Lobby Event 상세 → `[⚙]` 탭
   - 권한: Admin / Operator
   - 저장: `configs(scope='event', scope_id=<event_id>)`

4. **Table Settings**
   - 진입: CC 상단 `[⚙ Table]` 버튼 (해당 테이블만 적용)
   - 권한: Operator (자기 할당 테이블만)
   - 저장: `configs(scope='table', scope_id=<table_id>)`

모든 진입점에서 "상위 스코프 상속" 배지 표시: "이 값은 Event Settings 에서 상속됨" → 변경 시 현 scope 에 override 레코드 생성.

---

## 적용 시점

| 설정 유형 | IDLE (핸드 미진행) | 핸드 진행 중 |
|----------|:------------------:|:-----------:|
| Outputs / Display | 즉시 | 다음 핸드 시작 시 |
| GFX (스킨/로고) | 즉시 | 현 핸드 유지, 다음 핸드 반영 |
| Rules | 즉시 | 다음 핸드 (규칙 중간 변경 금지) |
| Stats | 즉시 | 즉시 (화면 표시만 영향) |
| Preferences | 즉시 | 즉시 (운영자 개인 UI) |

상세: `../2.2 Backend/APIs/WebSocket_Events.md §5.2 핸드 중간 설정 변경 지연`

---

## WebSocket 전달

`ConfigChanged` 이벤트 payload (WebSocket_Events.md §5.1):
```json
{
  "scope": "event",
  "scope_id": 17,
  "config_key": "overlay.skin_id",
  "old_value": "1",
  "new_value": "2",
  "actor_user_id": 3,
  "applied_at_hint": "next_hand"
}
```

CC 수신 시 필터링:
```python
if config.scope == 'global':
    apply(config)  # 모든 CC 에 반영
elif config.scope == 'series' and my_table.series_id == config.scope_id:
    apply(config)
elif config.scope == 'event' and my_table.event_id == config.scope_id:
    apply(config)
elif config.scope == 'table' and my_table.table_id == config.scope_id:
    apply(config)
else:
    ignore(config)  # 이 CC 와 무관
```

---

## RFID 모드

`rfid_mode` (Real / Mock) 는 **`scope='table'`** 로만 저장 가능 (각 테이블의 물리 리더 상태는 독립적). Global/Series/Event scope 사용 금지 — 테이블 단위 CHECK 는 UI 레이어에서 가드.

---

## Rules 탭 상세 (구 AT-06 Game Settings 통합)

> 2026-04-16: 구 `Game_Settings_Modal.md` (BS-05-08, AT-06)의 필드를 Rules 탭으로 통합. AT-06은 독립 모달이 아닌 **Table Settings Rules 탭**으로 재정의. 진입 경로: CC Toolbar `[⚙]` → Table Settings → Rules 탭.

### 필드 목록 및 카테고리

3개 용어 축 정의는 `Game_Settings_Modal.md §0` 참조.

| 필드 | 설명 | 카테고리 | 편집 가능 시점 |
|------|------|:--------:|----------------|
| `game_type` | Hold'em / PLO / Mix 등 | **A** | 핸드 간격 only |
| `blind_structure_id` | 블라인드 구조 전환 | **A** | 핸드 간격 only |
| `ante_override` | 앤티 금액 임시 조정 | **A** | 핸드 간격 only |
| `straddle_enabled_seats` | 좌석별 Straddle ON/OFF | **B** | 항상 가능 (다음 핸드부터 적용) |
| `allow_run_it_twice` | Run It Twice 허용 | **A** | 핸드 간격 only |
| `cap_bb_multiplier` | Cap Game BB 배수 (None = 무제한) | **A** | 핸드 간격 only |
| `rfid_mode` | RFID Real/Mock | **C** | 테이블 라이브 중 항상 가능 |
| `shot_clock_seconds` | 샷 클럭 초 | **B** | 항상 가능 (다음 핸드부터) |
| `time_bank_seconds` | 타임 뱅크 초 | **B** | 항상 가능 (다음 핸드부터) |

### 카테고리 렌더링 규칙

| 카테고리 | 핸드 간격 | 핸드 진행 중 |
|:--------:|:---------:|:----------:|
| **A** | 표시 + 편집 가능 | **숨김** (placeholder: "현재 {N}번 핸드 진행 중") |
| **B** | 표시 + 편집 가능 | 표시 + 편집 가능 |
| **C** | 표시 + 편집 가능 | 표시 + 편집 가능 |

> 카테고리 A 필드는 핸드 진행 중 disabled가 아니라 **섹션 자체가 비노출** — 운영자가 실수로 건드릴 경로를 원천 차단.

### 필드 상세 규격

구현 상세(검증 규칙, UI 컴포넌트, 에러 메시지)는 `Command_Center_UI/Game_Settings_Modal.md` 참조. 해당 문서는 이 탭의 **상세 규격 부록**으로 기능한다.

---

## 미해결 (team4 검토 대상)

- **user_preferences 분리**: 오퍼레이터 단축키/테마 등 사용자 개인 설정을 `configs` 에 섞을지, 별도 `user_preferences(user_id, key, value)` 테이블로 분리할지 — G4-B 초안은 후자 가정. team4 decision 필요.
- **Settings 변경 Audit**: `audit_logs` 에 scope/scope_id 기록 — Schema/Audit 정책 확정 후 반영.
- **Lobby-Only vs CC 진입**: 현재 초안은 Lobby 에서 Series/Event, CC 에서 Table. 둘 다 진입하는 탭도 있어야 할지 team4 UX 결정.
