# CCR-DRAFT: BS-05에 AT 화면 체계(AT-00~AT-07) 도입

- **제안팀**: team4
- **제안일**: 2026-04-10
- **영향팀**: [team1, team2]
- **변경 대상 파일**: contracts/specs/BS-05-command-center/BS-05-00-overview.md, contracts/specs/BS-05-command-center/BS-05-03-seat-management.md, contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md, contracts/specs/BS-05-command-center/BS-05-08-game-settings-modal.md, contracts/specs/BS-05-command-center/BS-05-09-player-edit-modal.md
- **신규 파일**: BS-05-08-game-settings-modal.md, BS-05-09-player-edit-modal.md
- **변경 유형**: add
- **변경 근거**: WSOP LIVE의 `EBS UI Design Action Tracker.md`(743줄)와 `EBS UI Design.md` §3 Action Tracker(421줄)에 정의된 8개 화면(AT-00~AT-07) 체계와 7 Zone(M-01~M-07) 구조를 BS-05 계약에 반영. 이미 `team4-cc/ui-design/reference/action-tracker/`에 복사본이 존재하지만 계약 문서에 구조적 핵심이 누락되어, Team 4 구현자가 복사본과 계약 사이에서 어느 쪽을 따를지 판단이 모호함. 근거: Miller's Law(7±2) 기반 인지 부하 최소화, 6시간+ 라이브 방송 피로 최소화 (출처: `team4-cc/ui-design/reference/action-tracker/analysis/EBS-AT-Design-Rationale.md` §3.1).

## 변경 요약

현재 BS-05는 CC를 "단일 화면(상단바 + 중앙 테이블 + 하단 액션 패널)"으로 가정한다. WSOP 원본은 8개 독립 화면(AT-00 Login, AT-01 Main, AT-02 Action View, AT-03 Card Selector, AT-04 Statistics, AT-05 RFID Register, AT-06 Game Settings, AT-07 Player Edit)으로 분리하며, AT-01 내부는 7 Zone(M-01~M-07)으로 그룹핑된다. 이 구조를 BS-05에 반영하여:

1. `BS-05-00-overview.md`에 AT 화면 체계 및 Zone 구조 정의 추가
2. `BS-05-04-manual-card-input.md`에 AT-03 모달 전환 규칙 추가
3. `BS-05-08-game-settings-modal.md` 신규 작성 (AT-06, Option A 최소 범위)
4. `BS-05-09-player-edit-modal.md` 신규 작성 (AT-07)

## 변경 내용 (섹션별)

### 1. BS-05-00-overview.md §화면 구조 개정

**현재**:
> "CC 화면은 상단 바 + 중앙 테이블 + 하단 액션 패널로 구성"

**변경**:
> CC 앱은 AT-00~AT-07 **8개 화면**으로 구성된다. AT-01 Main은 M-01~M-07 **7개 Zone**으로 그룹핑되며 Miller's Law(7±2)에 기반한다.
>
> #### 화면 카탈로그
>
> | 화면 ID | 이름 | 크기 | 진입 경로 | 참조 |
> |---------|------|------|---------|------|
> | AT-00 | Login | 480×360 | 앱 시작 | BS-01-auth |
> | AT-01 | Main | 720 min-width, auto height | Login 성공 | 본 문서 |
> | AT-02 | Action View | AT-01 Layer 4~6 (오버레이 영역) | 핸드 진행 중 | BS-05-01, BS-05-02 |
> | AT-03 | Card Selector | 560×auto (모달) | 카드 슬롯 탭 또는 RFID Fallback | BS-05-04 |
> | AT-04 | Statistics | — | 메뉴 | BS-05-07-stats.md (신규 예정) |
> | AT-05 | RFID Register | — | Settings 또는 메뉴 | BS-04-rfid |
> | AT-06 | Game Settings | 모달 | 메뉴 | BS-05-08-game-settings-modal.md (신규) |
> | AT-07 | Player Edit | 모달 | 좌석 롱프레스/컨텍스트 | BS-05-09-player-edit-modal.md (신규) |
>
> #### AT-01 Main의 7 Zone 구조
>
> | Zone | 이름 | 기능 |
> |:----:|------|------|
> | M-01 | Toolbar | NEW HAND, HIDE GFX 토글, Menu |
> | M-02 | Info Bar | Hand #, Pot, SB/BB/Ante |
> | M-03 | 좌석 라벨 행 | 포지션 마커 (Dealer/SB/BB/UTG) |
> | M-04 | 스트래들 토글 행 | 좌석별 Straddle ON/OFF |
> | M-05 | 좌석 카드 행 | 10좌석 상태 (Active/Empty/Folded/All-In) |
> | M-06 | 블라인드 패널 | WriteGameInfo 프로토콜 필드 |
> | M-07 | 액션 패널 | FOLD/CALL/BET/RAISE/ALL-IN + UNDO |
>
> #### 반응형 해상도
>
> - **최소 폭**: 720px (568px 이하 미지원)
> - **높이**: auto (CSS Container Queries 기반)
> - **근거**: Nielsen Heuristic #7 (Flexibility and Efficiency of Use)

### 2. BS-05-04-manual-card-input.md §화면 전환 개정

**현재**:
> "RFID 미감지 5초 후 수동 입력 모드 활성"

**변경**:
> AT-01 Main의 카드 슬롯을 탭하거나 RFID Fallback이 발생하면 **AT-03 Card Selector 모달**이 열린다.
>
> - **크기**: 560×auto
> - **선택 단위**: 1회 진입에 1장만 선택 가능. 여러 장이 필요하면 반복 진입.
> - **OK**: 서버에 선택 카드 전송 후 AT-01로 복귀
> - **Back / Esc**: 전송 없이 AT-01로 복귀
> - **이미 사용된 카드**: 흐리게 표시(opacity 0.4), 선택 불가
>
> 예: TURN 상태에서 SEAT1(2장) + SEAT2(2장) + 보드(3장) = 7장이 흐리게 표시되고, 나머지 45장만 선택 가능.

### 3. BS-05-08-game-settings-modal.md (신규 파일)

```markdown
# BS-05-08 Game Settings Modal (AT-06)

> **참조**: BS-05-00-overview §화면 카탈로그, BS-03-settings (글로벌 설정과의 경계)

## 개요

AT-06은 **핸드 진행 중** 운영자가 즉시 변경해야 하는 게임 규칙을 편집하는 모달이다. BS-03 Settings Global과 의도적으로 **경계를 분리**하며, Lobby를 경유한 원격 변경은 방송 지연 원인이 되므로 CC 내부에서 직접 변경할 수 있어야 한다.

## 범위 (Option A: 최소 채택)

| 필드 | 설명 | 편집 가능 시점 |
|------|------|--------------|
| game_type | Hold'em / PLO / Mix 등 | IDLE 상태에서만 |
| blind_structure_id | 블라인드 구조 전환 | IDLE 상태에서만 |
| ante_override | 앤티 금액 임시 조정 | IDLE 상태에서만 |
| straddle_enabled_seats | 좌석별 Straddle ON/OFF | 항상 가능 (다음 핸드 적용) |
| allow_run_it_twice | Run It Twice 허용 | IDLE 상태에서만 |
| cap_bb_multiplier | Cap Game BB 배수 (None=무제한) | IDLE 상태에서만 |

## 범위 외 (BS-03 Settings Global 담당)

- 테이블 공통 설정 (테이블 이름, 좌석 수, 카메라 각도)
- 스킨/오버레이 시각 설정
- NDI/HDMI 출력 설정
- 사용자 계정 및 권한

## UI

- 모달 크기: 600×auto
- 탭: `Game` / `Blinds` / `Rules`
- 하단 버튼: `Apply` (적용) / `Cancel` (취소)
- 핸드 진행 중 편집 불가 필드는 회색 + 툴팁 "Only editable in IDLE state"

## 트리거

- M-01 Toolbar의 `Menu` → `Game Settings` 선택
- 키보드 단축키: 미지정 (충돌 회피)

## 상태별 동작

| Table FSM | Hand FSM | 접근 |
|-----------|----------|:----:|
| SETUP | — | ✅ 전체 편집 가능 |
| LIVE | IDLE | ✅ 전체 편집 가능 |
| LIVE | PRE_FLOP~SHOWDOWN | ⚠️ Straddle만 편집 가능 |
| PAUSED | — | ⚠️ 읽기 전용 |
| CLOSED | — | ❌ 접근 불가 |

## 참조

- BS-05-00-overview §화면 카탈로그
- BS-03-settings §글로벌 설정 경계
- BS-06-00-triggers §게임 전환 트리거
```

### 4. BS-05-09-player-edit-modal.md (신규 파일)

```markdown
# BS-05-09 Player Edit Modal (AT-07)

> **참조**: BS-05-03-seat-management §좌석 컨텍스트 메뉴, API-01 §PATCH /players/{id}

## 개요

AT-07은 좌석의 플레이어 정보를 편집하는 모달이다. 좌석 롱프레스 또는 컨텍스트 메뉴 `Edit Player`로 진입한다.

## 필드

| 필드 | 타입 | 편집 가능 시점 |
|------|------|--------------|
| name | string(max 40) | IDLE 상태에서만 |
| country_code | ISO 3166-1 alpha-2 | IDLE 상태에서만 |
| sit_out_toggle | bool | 항상 가능 |
| current_stack | int | 항상 가능 (Chip Adjustment 권한 필요) |

## 트리거

- M-05 Seat Cell 롱프레스 (500ms)
- 우클릭 컨텍스트 메뉴 → `Edit Player`
- 키보드 단축키: Tab으로 좌석 포커스 → Enter → `Edit Player`

## UI

- 모달 크기: 480×auto
- 하단 버튼: `Save` / `Cancel`
- 핸드 진행 중 편집 불가 필드는 회색 + 툴팁 "Only editable in IDLE state"

## 서버 프로토콜

- PATCH `/players/{id}` (name, country_code 변경)
- WebSocket `PlayerUpdated` 이벤트 발행 → BO → 다른 테이블/Lobby 동기화
- sit_out_toggle은 `SeatStatusUpdated` 이벤트로 별도 처리 (BS-05-03 §Sitting Out 참조)

## 검증

- name: 1~40자, 공백 금지
- country_code: ISO 3166-1 alpha-2 리스트 검증
- current_stack: 음수 불가, 테이블 stack_cap 초과 불가

## 참조

- BS-05-03-seat-management §좌석 컨텍스트 메뉴
- API-01-backend-endpoints §PATCH /players/{id}
- API-05-websocket-events §PlayerUpdated, SeatStatusUpdated
```

## Diff 초안

```diff
 # BS-05-00-overview.md

 ## 화면 구조

-CC 화면은 상단 바 + 중앙 테이블 + 하단 액션 패널로 구성된다.
+CC 앱은 AT-00~AT-07 **8개 화면**으로 구성된다.
+AT-01 Main은 M-01~M-07 **7개 Zone**으로 그룹핑되며 Miller's Law(7±2)에 기반한다.
+
+### 화면 카탈로그
+
+| 화면 ID | 이름 | 크기 | 진입 경로 |
+|---------|------|------|---------|
+| AT-00 | Login | 480×360 | 앱 시작 |
+| AT-01 | Main | 720 min-width, auto height | Login 성공 |
+| AT-02 | Action View | AT-01 Layer 4~6 | 핸드 진행 중 |
+| AT-03 | Card Selector | 560×auto (모달) | 카드 슬롯 탭/RFID Fallback |
+| AT-04 | Statistics | — | 메뉴 |
+| AT-05 | RFID Register | — | Settings/메뉴 |
+| AT-06 | Game Settings | 모달 | 메뉴 |
+| AT-07 | Player Edit | 모달 | 좌석 롱프레스 |
+
+### AT-01 Main 7 Zone 구조
+
+| Zone | 이름 | 기능 |
+|:----:|------|------|
+| M-01 | Toolbar | NEW HAND, HIDE GFX, Menu |
+| M-02 | Info Bar | Hand #, Pot, SB/BB/Ante |
+| M-03 | 좌석 라벨 행 | 포지션 마커 |
+| M-04 | 스트래들 토글 행 | 좌석별 Straddle |
+| M-05 | 좌석 카드 행 | 10좌석 상태 |
+| M-06 | 블라인드 패널 | WriteGameInfo 필드 |
+| M-07 | 액션 패널 | FOLD/CALL/BET/RAISE/ALL-IN + UNDO |
+
+### 반응형 해상도
+
+- 최소 폭: 720px (568px 이하 미지원)
+- 높이: auto (CSS Container Queries)
+- 근거: Nielsen Heuristic #7
```

## 영향 분석

### Team 1 (Lobby)
- **영향**: AT-06 Game Settings가 신설되면 Lobby의 Settings Global과 중복 영역 조정 필요. BS-03-settings와의 경계를 본 CCR의 `BS-05-08` 범위 표(`Option A`)에 맞춰 재정의.
- **필요 작업**: BS-02-lobby에 "Game Settings는 CC의 AT-06에서 직접 편집. Lobby는 글로벌/공통만 제공" 명시 (별도 후속 CCR 필요 없이 참조 추가로 충분).
- **예상 리뷰 시간**: 2시간

### Team 2 (Backend)
- **영향**: 
  - AT-04 Statistics 화면의 데이터 공급 API 확인 (API-01 통계 엔드포인트 존재 여부).
  - AT-07 Player Edit의 PATCH `/players/{id}` 엔드포인트와 `PlayerUpdated` WebSocket 이벤트 확인.
  - BS-05-08 Game Settings의 `game_type`, `blind_structure_id`, `straddle_enabled_seats` 변경이 API-01/API-05에 이미 반영되어 있는지 점검.
- **구현 영향**: 문서 레벨 변경이므로 코드 수정은 AT-04 Statistics 엔드포인트 부재 시에만 발생.
- **예상 리뷰 시간**: 1시간

### Team 4 (self)
- **영향**: 
  - BS-05-08, BS-05-09 신규 문서 2개를 Conductor가 작성하는 동안 Team 4는 `team4-cc/src/lib/features/command_center/screens/` 아래 8개 화면 스텁 생성.
  - AT 화면 명칭을 코드 구조에 1:1 매핑: `login/`, `main/`, `action_view/`, `card_selector/`, `stats/`, `rfid_register/`, `game_settings/`, `player_edit/`
- **예상 작업 시간**: 문서 리뷰 2시간 + 스텁 생성 4시간 (CCR 승인 후)

### 마이그레이션
- 없음 (신규 구조 도입)

## 대안 검토

### Option 1: AT 화면 체계 미채택
- **장점**: 구조 변경 없음, 기존 BS-05 유지
- **단점**: 
  - WSOP 원본 조직 자산을 계약에 반영하지 못함
  - Team 4 구현자가 `team4-cc/ui-design/reference/action-tracker/` 복사본과 BS-05 계약 사이에서 혼란
  - 계약 문서의 권위가 "reference보다 낮은" 상태로 남음
- **채택**: ❌

### Option 2: AT 화면 체계 부분 채택 (본 CCR 제안)
- **내용**: AT-00~AT-07 전체 채택하되 AT-06은 Option A(최소 범위)로 좁힘
- **장점**: 
  - 조직 자산 재사용 + EBS의 Lobby Settings Global 철학과의 절충
  - BS-03 Settings와 중복 최소화
  - AT-06은 "운영자가 핸드 중 즉시 바꿔야 하는 것"만 담당
- **단점**: BS-03과 BS-05-08의 경계를 명확히 설명하는 참조 섹션 유지 비용
- **채택**: ✅

### Option 3: AT 화면 체계 완전 채택
- **내용**: WSOP 원본 100% 복제
- **장점**: 원본과 완전 일치
- **단점**: 
  - AT-06이 BS-03 Settings와 완전히 중복되어 혼란
  - Lobby Settings Global 방침(memory `feedback_settings_global.md`)과 충돌
- **채택**: ❌

## 검증 방법

### 1. 문서 리뷰
- Team 1/2/4가 BS-05-00 개정안과 BS-05-08, BS-05-09 신규 문서를 리뷰하여 AT-06 경계 합의
- Conductor가 BS-03-settings와 BS-05-08의 범위 표가 상호 배타적인지 확인

### 2. 모형 검증
- `team4-cc/ui-design/reference/action-tracker/mockups/v4/` HTML 목업이 8개 화면 모두를 커버하는지 체크
- 누락된 화면이 있으면 모형 작성 백로그에 추가 (`docs/backlog/team4.md`)

### 3. 구현 정합성
- CCR 승인 후 Team 4가 `team4-cc/src/lib/features/command_center/screens/{login,main,action_view,card_selector,stats,rfid_register,game_settings,player_edit}/` 8개 폴더 스텁 생성
- 각 스텁에서 BS-05 해당 섹션을 주석 참조 (`// See: contracts/specs/BS-05-command-center/BS-05-08-game-settings-modal.md`)

### 4. 체크리스트 (WSOP 원본 대조)
- [ ] AT-00 Login: BS-01-auth 참조로 반영됨
- [ ] AT-01 Main: BS-05-00 §화면 카탈로그에 반영됨
- [ ] AT-02 Action View: BS-05-01, BS-05-02 참조로 반영됨
- [ ] AT-03 Card Selector: BS-05-04 §화면 전환으로 반영됨
- [ ] AT-04 Statistics: BS-05-07 신규 예정으로 표시됨 (본 CCR 범위 외, 후속 CCR 필요)
- [ ] AT-05 RFID Register: BS-04-rfid 참조로 반영됨
- [ ] AT-06 Game Settings: BS-05-08 신규로 반영됨
- [ ] AT-07 Player Edit: BS-05-09 신규로 반영됨

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (AT-06 vs Lobby Settings Global 경계)
- [ ] Team 2 기술 검토 (API-01 통계/플레이어 엔드포인트 확인)
- [ ] Team 4 기술 검토 (구현 가능성, 스텁 매핑)
