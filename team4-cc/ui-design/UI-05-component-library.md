# UI-05 Component Library — 재사용 컴포넌트 목록

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 공통/Lobby/CC/Overlay/Settings 컴포넌트 정의 |

---

## 개요

EBS 전체 앱에서 재사용되는 UI 컴포넌트 목록이다. 각 컴포넌트의 props, state, 주요 이벤트를 정의한다.

---

## 1. 공통 컴포넌트

### Button

| 속성 | 타입 | 설명 |
|------|------|------|
| `variant` | primary / secondary / danger / ghost | 스타일 변형 |
| `size` | sm / md / lg | 크기 (32 / 40 / 48px 높이) |
| `disabled` | boolean | 비활성 상태 |
| `icon` | IconData? | 좌측 아이콘 (선택) |
| `label` | string | 버튼 텍스트 |
| **이벤트** | `onPressed` | 클릭/탭 콜백 |

### TextField

| 속성 | 타입 | 설명 |
|------|------|------|
| `value` | string | 현재 값 |
| `placeholder` | string | 빈 상태 안내 텍스트 |
| `type` | text / password / number / search | 입력 타입 |
| `error` | string? | 에러 메시지 (표시 시 border-error) |
| `disabled` | boolean | 비활성 |
| **이벤트** | `onChange`, `onSubmit` | 값 변경, 제출 |

### Dropdown

| 속성 | 타입 | 설명 |
|------|------|------|
| `options` | List<{value, label}> | 선택지 목록 |
| `selected` | value | 현재 선택값 |
| `placeholder` | string | 미선택 시 텍스트 |
| `disabled` | boolean | 비활성 |
| **이벤트** | `onSelect` | 선택 변경 |

### Toggle

| 속성 | 타입 | 설명 |
|------|------|------|
| `value` | boolean | ON/OFF 상태 |
| `label` | string | 라벨 텍스트 |
| `disabled` | boolean | 비활성 |
| **이벤트** | `onToggle` | 토글 변경 |

### Slider

| 속성 | 타입 | 설명 |
|------|------|------|
| `min` | number | 최소값 |
| `max` | number | 최대값 |
| `value` | number | 현재값 |
| `step` | number | 증가 단위 |
| `disabled` | boolean | 비활성 |
| **이벤트** | `onChange` | 값 변경 |

### Modal

| 속성 | 타입 | 설명 |
|------|------|------|
| `title` | string | 모달 헤더 |
| `open` | boolean | 표시/숨김 |
| `size` | sm / md / lg / full | 모달 크기 |
| `closeOnOverlay` | boolean | 배경 클릭 닫기 |
| **이벤트** | `onClose` | 닫기 콜백 |
| **슬롯** | `body`, `footer` | 내용, 하단 버튼 영역 |

### Toast

| 속성 | 타입 | 설명 |
|------|------|------|
| `message` | string | 알림 메시지 |
| `type` | success / error / warning / info | 색상/아이콘 |
| `duration` | number (ms) | 자동 닫힘 시간 (기본 3000) |
| `position` | top-right / bottom-center | 표시 위치 |

### Badge

| 속성 | 타입 | 설명 |
|------|------|------|
| `label` | string | 텍스트 |
| `variant` | default / success / error / warning / info | 색상 |
| `size` | sm / md | 크기 |

---

## 2. Lobby 컴포넌트

### TableCard

테이블 목록에서 각 테이블을 카드 형태로 표시.

| 속성 | 타입 | 설명 |
|------|------|------|
| `table` | TableModel | 테이블 데이터 |
| `status` | TableFSM | EMPTY/SETUP/LIVE/PAUSED/CLOSED |
| `isFeature` | boolean | Feature Table 여부 |
| `rfidStatus` | online / offline / error | RFID 상태 |
| `outputStatus` | active / inactive | NDI/HDMI 상태 |
| `operator` | string? | 접속 Operator 이름 |
| `handNumber` | number? | 현재 핸드 번호 (LIVE시) |
| **이벤트** | `onTap`, `onLaunch`, `onSettings` | 카드 탭, Launch, Settings |

### PlayerRow

플레이어 목록 테이블의 1행.

| 속성 | 타입 | 설명 |
|------|------|------|
| `seatIndex` | number (0~9) | 좌석 번호 |
| `player` | PlayerModel? | 플레이어 (null=빈 좌석) |
| `status` | SeatFSM | VACANT/OCCUPIED/RESERVED |
| `stack` | number? | 칩 스택 |
| **이벤트** | `onTap`, `onRemove` | 행 탭, 제거 |

### BreadcrumbNav

현재 위치 경로 표시 + 빠른 레벨 이동.

| 속성 | 타입 | 설명 |
|------|------|------|
| `items` | List<{label, path}> | 경로 항목 |
| `current` | number | 현재 활성 인덱스 |
| **이벤트** | `onNavigate(index)` | 해당 레벨로 이동 |

### CCStatusIndicator

활성 CC 상태를 드롭다운으로 표시.

| 속성 | 타입 | 설명 |
|------|------|------|
| `activeCCs` | List<CCStatus> | 활성 CC 목록 |
| `expanded` | boolean | 드롭다운 펼침 |
| **이벤트** | `onSelect(tableId)` | CC 전환 |
| **State** | WebSocket 실시간 | `operator_connected` 이벤트 |

---

## 3. CC 컴포넌트

### SeatWidget

타원형 테이블 위 각 좌석 표시.

| 속성 | 타입 | 설명 |
|------|------|------|
| `seatIndex` | number (0~9) | 좌석 번호 |
| `player` | PlayerModel? | 플레이어 정보 |
| `cards` | List<Card> | 홀카드 (0~2장) |
| `stack` | number | 칩 스택 |
| `equity` | double? | 승률 (0.0~1.0) |
| `lastAction` | ActionType? | 마지막 액션 배지 |
| `position` | D / SB / BB / STR / null | 포지션 |
| `isActionOn` | boolean | 현재 액션 대상 (glow) |
| `isFolded` | boolean | 폴드 상태 (반투명) |
| **이벤트** | `onTap` | 좌석 상세 패널 열기 |

### ActionButton

하단 액션 패널의 개별 버튼.

| 속성 | 타입 | 설명 |
|------|------|------|
| `action` | ActionType | NEW_HAND/DEAL/FOLD/CHECK/BET/CALL/RAISE/ALLIN |
| `enabled` | boolean | HandFSM + 게임 상태 기반 활성/비활성 |
| `label` | string | 표시 텍스트 (동적: "CALL 400") |
| `shortcutKey` | Key | 단축키 (N/D/F/C/B/R/A) |
| **이벤트** | `onPressed` | 액션 전송 → Game Engine |

### CardGrid

수동 카드 입력 화면의 4x13 그리드.

| 속성 | 타입 | 설명 |
|------|------|------|
| `usedCards` | Set<Card> | 이미 딜된 카드 (비활성) |
| `selectedCards` | List<Card> | 현재 선택된 카드 |
| `maxSelect` | number | 최대 선택 수 |
| **이벤트** | `onSelect(card)`, `onConfirm` | 카드 선택, 확정 |

### BetSlider

금액 입력 패널의 슬라이더 + 프리셋.

| 속성 | 타입 | 설명 |
|------|------|------|
| `min` | number | 최소 베팅액 |
| `max` | number | 최대 베팅액 (stack) |
| `pot` | number | 현재 팟 (프리셋 계산용) |
| `value` | number | 현재 입력 금액 |
| `presets` | List<{label, value}> | MIN/1/2 POT/POT/ALL-IN |
| **이벤트** | `onChange`, `onConfirm`, `onCancel` | 변경/확정/취소 |

### UndoList

최근 이벤트 로그 + UNDO 기능.

| 속성 | 타입 | 설명 |
|------|------|------|
| `events` | List<GameEvent> | 최근 이벤트 (max 5) |
| `canUndo` | boolean | UNDO 가능 여부 |
| **이벤트** | `onUndo` | 마지막 이벤트 되돌리기 |

### HandTimer

핸드 경과 시간 표시 (TBD).

| 속성 | 타입 | 설명 |
|------|------|------|
| `startTime` | DateTime | 핸드 시작 시각 |
| `running` | boolean | 타이머 동작 중 |
| **State** | 내부 | 경과 시간 mm:ss |

---

## 4. Overlay 컴포넌트

### CardImage

카드 이미지 렌더링 (홀카드, 보드 공용).

| 속성 | 타입 | 설명 |
|------|------|------|
| `card` | Card (suit + rank) | 카드 데이터 |
| `faceUp` | boolean | 앞면/뒷면 |
| `size` | sm / md / lg | 48px / 72px / 96px 너비 |
| `highlighted` | boolean | 승리 카드 하이라이트 |
| **State** | Rive 애니메이션 | flip, slide 효과 |

### EquityBar

승률 프로그레스 바.

| 속성 | 타입 | 설명 |
|------|------|------|
| `equity` | double (0.0~1.0) | 승률 |
| `showLabel` | boolean | % 텍스트 표시 |
| `color` | Color | 바 색상 (기본: primary) |
| **State** | 애니메이션 | 값 변경 시 부드러운 전환 |

### HandRankLabel

핸드 등급 텍스트 (예: "Pair of Aces").

| 속성 | 타입 | 설명 |
|------|------|------|
| `rank` | HandRank enum | 핸드 등급 |
| `highlighted` | boolean | 승리 핸드 강조 |
| **State** | 텍스트 | 등급명 자동 변환 |

### ActionBadge

플레이어 액션 시각적 배지.

| 속성 | 타입 | 설명 |
|------|------|------|
| `action` | ActionType | CHECK/FOLD/BET/CALL/RAISE/ALL-IN |
| `amount` | number? | 금액 (BET/RAISE 시) |
| `bounce` | boolean | 바운스 애니메이션 |
| **State** | Rive 애니메이션 | 등장 바운스, 페이드아웃 |

### PotDisplay

팟 표시 (메인 + 사이드).

| 속성 | 타입 | 설명 |
|------|------|------|
| `mainPot` | number | 메인 팟 금액 |
| `sidePots` | List<{amount, players}> | 사이드 팟 목록 |
| **State** | 애니메이션 | 금액 변경 시 카운트업 |

### DealerButton

딜러 위치 아이콘.

| 속성 | 타입 | 설명 |
|------|------|------|
| `seatIndex` | number | 딜러 좌석 번호 |
| `position` | Offset | 좌석 좌표 기반 위치 |
| **State** | 애니메이션 | 핸드 시작 시 슬라이드 이동 |

### LowerThird

하단 정보 스트립.

| 속성 | 타입 | 설명 |
|------|------|------|
| `blinds` | string | "100/200" |
| `pot` | number | 현재 팟 |
| `customText` | string | Admin 입력 텍스트 |
| `tickerStats` | List<{label, value}> | 티커 통계 |
| `scrollSpeed` | number | 스크롤 속도 |
| **State** | 애니메이션 | 티커 스크롤 |

---

## 5. Settings 컴포넌트

### TabNav

Settings 4탭 네비게이션 바.

| 속성 | 타입 | 설명 |
|------|------|------|
| `tabs` | List<{id, label}> | 탭 목록 |
| `activeTab` | string | 현재 활성 탭 |
| **이벤트** | `onTabChange(id)` | 탭 전환 |

### PresetSelector

스킨 갤러리 선택기.

| 속성 | 타입 | 설명 |
|------|------|------|
| `presets` | List<{id, name, thumbnail}> | 프리셋 목록 |
| `selected` | string | 현재 선택 ID |
| **이벤트** | `onSelect(id)` | 프리셋 선택 |

### SkinPreview

오버레이 실시간 미리보기.

| 속성 | 타입 | 설명 |
|------|------|------|
| `skinId` | string | 적용 스킨 ID |
| `resolution` | 1080p / 4K | 미리보기 해상도 |
| `sampleData` | GameState | 샘플 게임 데이터 |
| **State** | Flutter 렌더링 | 축소 비율 미리보기 |

### SliderWithLabel

값 라벨이 함께 표시되는 슬라이더.

| 속성 | 타입 | 설명 |
|------|------|------|
| `min` | number | 최소값 |
| `max` | number | 최대값 |
| `value` | number | 현재값 |
| `unit` | string | 단위 (sec, %, px) |
| `label` | string | 라벨 텍스트 |
| **이벤트** | `onChange` | 값 변경 |
