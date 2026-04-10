# BS-03-02 GFX — 그래픽 설정

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 스킨 선택, 레이아웃, 배치, 해상도 대응, 카드 렌더링 정의 |
| 2026-04-09 | SE 진입 추가 | Skin Editor 진입 워크플로우, GE 이동, 미리보기 화면 정의 |
| 2026-04-09 | Console PRD v9.7 재설계 | §2.8 기반 — Layout/Card & Player/Animation 3서브그룹, 14 컨트롤 |

---

## 개요

GFX 섹션은 Settings의 두 번째 탭으로, 오버레이의 **시각적 배치와 카드/애니메이션** 설정을 관리한다. 3-Column 구조: Layout(보드/플레이어 배치, 마진) → Card & Player(카드 공개, 폴드, 리더보드) → Animation(전환 효과, 액션 강조). Skin Editor는 Info Bar의 Load Skin 버튼(M-16)으로 접근한다.

> 참조: Console PRD v9.7 §2.8 GFX 탭

---

## 1. 컨트롤 목록

### 1.1 Layout 서브그룹 (ID 1~5, 1.5)

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 1 | Board Position | Select | Left | 보드 카드 위치 (Left/Right/Centre/Top) | Board Graphic 9-Grid 위치 |
| 2 | Player Layout | Select | Horizontal | 플레이어 배치 모드 (5개 옵션) | Player Graphic 배치 |
| 3 | X Margin | Slider | 0.04 | 좌우 여백 (0.0~1.0 정규화 좌표) | Safe Area 마진 |
| 4 | Top Margin | Slider | 0.05 | 상단 여백 (0.0~1.0) | Safe Area 마진 |
| 5 | Bot Margin | Slider | 0.04 | 하단 여백 (0.0~1.0) | Safe Area 마진 |
| 1.5 | Leaderboard Position | Select | Off | 리더보드 위치 (Off/Centre/Left/Right) | 리더보드 화면 배치 |

**Board Position 옵션**:

| 옵션 | RE enum | 보드 위치 |
|------|:-------:|----------|
| Left | 0 | 좌측 상단 |
| Centre | 1 | 중앙 상단 |
| Right | 2 | 우측 상단 |
| Top | — | EBS 전용 (중앙 최상단, 플레이어 위) |

**Player Layout 5개 옵션**: `gfx_vertical` + `gfx_bottom_up` + `gfx_fit` 3개 bool 조합.

| 옵션 | vertical | bottom_up | fit | 설명 |
|------|:--------:|:---------:|:---:|------|
| Horizontal | false | — | — | 하단 가로 1열 배치 |
| Vert-Bot-Spill | true | true | false | 좌우 세로, 하단→상단, 화면 밖 허용 |
| Vert-Bot-Fit | true | true | true | 좌우 세로, 하단→상단, 화면 안 강제 |
| Vert-Top-Spill | true | false | false | 좌우 세로, 상단→하단, 화면 밖 허용 |
| Vert-Top-Fit | true | false | true | 좌우 세로, 상단→하단, 화면 안 강제 |

**Leaderboard Position**: 역설계 9개 위치를 EBS에서 4개로 축소 (top/bottom 6개는 Graphic 겹침 위험으로 제거).

| EBS 옵션 | RE enum 매핑 | 화면 위치 |
|----------|:-----------:|----------|
| Off | — | 리더보드 표시 안 함 |
| Centre | 0 | 화면 정중앙 |
| Left | 4 (left_centre) | 좌측 중앙 |
| Right | 5 (right_centre) | 우측 중앙 |

### 1.2 Card & Player 서브그룹 (ID 6~9)

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 6 | Reveal Players | Select | Immediate | 홀카드 공개 시점 | 홀카드 시각 효과 |
| 7 | How to Show Fold | Select + Input[type=number] | Immediate | 폴드 표시 방식 + 지연 시간(초) | 폴드 플레이어 제거 타이밍 |
| 8 | Reveal Cards | Select | Immediate | 카드 공개 연출 (6개 옵션) | 카드 공개 시각 효과 |
| 9 | Show Leaderboard | Switch + Settings | OFF | 핸드 후 리더보드 자동 표시 | 리더보드 자동 팝업 |

**Reveal Players 옵션**: Immediate / On Action / After Bet / On Action + Next

**Reveal Cards 6개 옵션**:

| 옵션 | enum | 트리거 시점 |
|------|:----:|-----------|
| Immediate | 0 | 카드 딜 즉시 |
| After Action | 1 | 해당 플레이어 첫 액션 후 |
| End of Hand | 2 | 핸드 완전 종료 후 |
| Never | 3 | 수동 공개만 허용 |
| Showdown Cash | 4 | 쇼다운 시 (캐시 게임) |
| Showdown Tourney | 5 | 쇼다운 시 (토너먼트) |

**Show Leaderboard Settings** (체크박스 활성화 시 노출):

| 설정 | ConfigurationPreset 필드 | 기본값 | 설명 |
|------|--------------------------|--------|------|
| Auto Stats | `auto_stats` | false | 핸드 사이 자동 리더보드 표시 |
| Display Time | `auto_stats_time` | 10 (초) | 자동 표시 지속 시간 |
| Start After Hand | `auto_stats_first_hand` | 5 | 통계 수집 시작 핸드 번호 |
| Update Interval | `auto_stats_hand_interval` | 1 | 갱신 주기 (핸드 수) |

### 1.3 Animation 서브그룹 (ID 10~13)

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 12 | Transition In | Select + Slider | Default, 0.3s | 등장 애니메이션 타입 + 시간 | Player/Board 등장 효과 |
| 13 | Transition Out | Select + Slider | Default, 0.3s | 퇴장 애니메이션 타입 + 시간 | Player/Board 퇴장 효과 |
| 10 | Indent Action Player | Switch | ON | 액션 플레이어 들여쓰기 | Action-on 플레이어 시각 구분 |
| 11 | Bounce Action Player | Switch | OFF | 액션 플레이어 바운스 효과 | Action-on 반짝임+바운스 |

**Transition 타입 4종**:

| 타입 | enum | 효과 |
|------|:----:|------|
| Default (Fade) | 0 | 투명→불투명 페이드 |
| Slide | 1 | 화면 밖→안 슬라이드 |
| Pop | 2 | 0→100% 스케일 팝업 |
| Expand | 3 | 중심선→전체 확대 |

시간 범위: 0.1~2.0초. Indent와 Bounce는 동시 활성화 가능.

---

## 2. Skin Editor 진입

Settings GFX 섹션이 아닌 **Info Bar의 Load Skin 버튼(M-16)**으로 접근한다.

### 2.1 진입 조건

| 조건 | 설명 |
|------|------|
| 역할 | Admin 또는 Designer (Operator/Viewer 접근 불가) |
| 핸드 상태 | 무관 (SE는 런타임에 영향 없음) |

### 2.2 SE → GE 진입

SE Element Grid의 7개 버튼 클릭 시 GE 화면으로 이동. 모드: Board, Blinds, Outs, Strip, History, Leaderboard, Field.

### 2.3 미리보기

SE/GE에서 [Open Preview] 클릭 시 별도 탭에서 오버레이 정적 렌더링. Save 시 WebSocket으로 자동 갱신.

---

## 3. 트리거

| 트리거 | 발동 주체 | 설명 |
|--------|:--------:|------|
| Settings 변경 | Admin 수동 | Admin이 GFX 탭에서 설정 변경 |
| `ConfigChanged` | 시스템 자동 | BO DB 갱신 후 WebSocket 이벤트 발행 |
| Preview 즉시 갱신 | 시스템 자동 | Layout/Card 변경 시 Preview Area 즉시 반영 |

---

## 4. 경우의 수 매트릭스

| 조건 | Layout 변경 | Card & Player 변경 | Animation 변경 |
|------|:----------:|:-----------------:|:-------------:|
| CC IDLE | 즉시 적용 (FREE) | 즉시 적용 (FREE) | 즉시 적용 (FREE) |
| CC 핸드 진행 중 | 즉시 적용 (FREE) | 다음 핸드 (CONFIRM) | 즉시 적용 (FREE) |
| BO 서버 미실행 | 변경 불가 | 변경 불가 | 변경 불가 |
| 수동 좌표 오버라이드 존재 | Layout 변경 시 초기화 확인 | — | — |

---

## 5. 유저 스토리

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| G-1 | Admin | Board Position을 Centre로 변경 | Preview에서 보드가 중앙 상단 이동 | — |
| G-2 | Admin | Player Layout을 Vert-Bot-Fit으로 변경 | 플레이어가 좌우 세로 배치, 화면 안 강제 | Horizontal 오버라이드: 초기화 확인 |
| G-3 | Admin | Reveal Cards를 "After Action"으로 변경 | 플레이어 액션 후에만 카드 공개 | 현재 핸드에는 미적용 |
| G-4 | Admin | Transition In을 Pop, 0.5s로 변경 | 등장 시 팝업 효과 0.5초 적용 | — |
| G-5 | Admin | Indent + Bounce 동시 활성화 | Action-on 플레이어에 들여쓰기 + 바운스 | — |
| G-6 | Admin | Show Leaderboard ON + Auto Stats ON | 핸드 사이 자동 리더보드 팝업 | 핸드 < Start After Hand: 미표시 |

---

## 비활성 조건

| 조건 | 영향 |
|------|------|
| Admin이 아닌 역할 | GFX 탭 접근 불가 |
| BO 서버 미실행 | 읽기 전용 |
