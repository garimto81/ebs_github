---
title: CR-team4-20260410-bs08-graphic-editor-new
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team4-20260410-bs08-graphic-editor-new
confluence-page-id: 3818882230
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818882230/EBS+CR-team4-20260410-bs08-graphic-editor-new
mirror: none
---

# CCR-DRAFT: BS-08 Graphic Editor 행동 명세 신규 작성 (WSOP 8모드)

- **제안팀**: team4
- **제안일**: 2026-04-10
- **영향팀**: [team1, team2]
- **변경 대상 파일**: contracts/specs/BS-08-graphic-editor/BS-08-00-overview.md, contracts/specs/BS-08-graphic-editor/BS-08-01-modes.md, contracts/specs/BS-08-graphic-editor/BS-08-02-skin-editor.md, contracts/specs/BS-08-graphic-editor/BS-08-03-color-adjust.md, contracts/specs/BS-08-graphic-editor/BS-08-04-rive-import.md, contracts/specs/BS-08-graphic-editor/BS-08-05-preview-apply.md
- **변경 유형**: add
- **변경 근거**: 현재 EBS 계약에 Graphic Editor 전용 행동 명세가 존재하지 않는다. team4 CLAUDE.md는 "Graphic Editor"를 Team 4의 3개 화면 중 하나로 명시하지만(`team4-cc/CLAUDE.md` §3개 화면), BS-01~07 어디에도 이 화면의 행동 명세가 없다. 반면 WSOP LIVE Confluence의 `EBS UI Design Action Tracker.md`와 `EBS UI Design.md` §3 Graphic Editor 섹션, 그리고 `team4-cc/ui-design/reference/skin-editor/EBS-Skin-Editor_v3.prd.md`에 PokerGFX 역설계 기반 8모드 구조(Board/Player/Dealer/House/Logo/Ticker/SSD/Action Clock)와 99개 컨트롤 매핑이 완전히 정의되어 있다. 이 조직 자산을 BS-08로 계약화하여 구현 혼란을 제거한다.

## 변경 요약

BS-08 Graphic Editor 명세 6개 파일 신규 작성:

1. `BS-08-00-overview.md`: 앱 역할, 3개 화면 중 Graphic Editor의 위치, 8모드 개요
2. `BS-08-01-modes.md`: 8개 편집 모드별 Canvas 크기, 서브요소, Transform 규칙
3. `BS-08-02-skin-editor.md`: Skin Editor 3열 레이아웃, 99개 컨트롤 카테고리
4. `BS-08-03-color-adjust.md`: Adjust Colours 모달 (Hue/Tint/3-Color Replace + WYSIWYG 프리뷰)
5. `BS-08-04-rive-import.md`: .riv 파일 Import/재생/Export 워크플로우
6. `BS-08-05-preview-apply.md`: Preview/Apply 흐름, Lobby Settings와의 연동

## 변경 내용

### 1. BS-08-00-overview.md (신규)

```markdown
# BS-08 Graphic Editor — 개요

> **참조**: BS-00 §앱 아키텍처, BS-07-overlay, BS-03-settings, team4-cc/CLAUDE.md §3개 화면

## 역할

Graphic Editor는 Team 4의 3개 화면(CC / Overlay / Graphic Editor) 중 하나로,
**Admin 권한 사용자가 Skin/Overlay의 시각 요소를 편집**하는 화면이다.

- 페르소나: Admin
- 사용 시점: 방송 전 준비 단계 또는 운영 중 긴급 디자인 수정
- 렌더링: Flutter 네이티브 UI + Rive 애니메이션 프리뷰

## 범위

Graphic Editor가 편집하는 대상:

1. **Skin**: BS-07의 visual asset 번들 (.gfskin 파일, ZIP + JSON)
2. **Overlay 요소 8종**: Board, Player, Dealer, House, Logo, Ticker, SSD, Action Clock
3. **Rive 애니메이션**: .riv 파일 Import, State Machine 설정, Export
4. **Color Adjustments**: Hue/Tint/3-Color Replace

편집 대상이 아닌 것:
- 오버레이 **레이아웃 좌표**: BS-07-04-scene-schema.md의 사전 정의만 사용
- **게임 규칙**: BS-06 Game Engine 영역
- **Output 설정** (NDI/HDMI/크로마키): `Overlay_Output_Events.md` (legacy-id: API-04) 영역

## 8 편집 모드

WSOP 원본(`team4-cc/ui-design/reference/skin-editor/EBS-Skin-Editor_v3.prd.md` §4)의
PokerGFX 역설계 결과를 따른다.

| # | 모드 | Canvas | 대상 요소 |
|:-:|------|:------:|---------|
| 1 | Board | 1920×1080 | 5장 커뮤니티 카드 영역 |
| 2 | Player | 480×270 | 10좌석 각각의 이름/스택/카드 |
| 3 | Dealer | 120×120 | Dealer button + 위치 인디케이터 |
| 4 | House | 1920×1080 | 브랜드 배경, 사이드 배너 |
| 5 | Logo | 512×512 | 대회 로고, 스폰서 로고 |
| 6 | Ticker | 1920×64 | 하단 스크롤 정보 바 |
| 7 | SSD (Side Stake Display) | 400×240 | 사이드 팟, 승리금 표시 |
| 8 | Action Clock | 240×240 | 타임 뱅크, 카운트다운 |

각 모드의 상세는 `BS-08-01-modes.md` 참조.

## Skin Editor

Graphic Editor의 핵심 하위 화면. 3열 Quasar QDialog 레이아웃(WSOP 원본 기준).
99개 컨트롤을 Category (CheckBox 58, ComboBox 48, Button 30, Spinner 16, Edit 6, Slider 2)로 분류.
상세는 `BS-08-02-skin-editor.md` 참조.

## 화면 전환 및 저장

- Graphic Editor 진입: Lobby → Graphic Editor 앱 Launch
- 저장: Local draft → `Apply` 버튼으로 Backend 업로드 → 활성 Skin 교체
- 되돌리기: 마지막 Apply 이전 상태로 Rollback (최대 10단계)

## 권한

- Admin만 편집 가능
- Operator는 읽기 전용 미리보기 가능
- Viewer는 접근 불가

## 참조

- BS-07-overlay §visual asset 로드
- BS-03-settings §Skin 목록 관리
- `Backend_HTTP.md` (legacy-id: API-01) §Skin 9개 API
```

### 2. BS-08-01-modes.md (신규)

```markdown
# BS-08-01 8 Editing Modes

> **참조**: team4-cc/ui-design/reference/skin-editor/EBS-Skin-Editor_v3.prd.md §4

## 모드 전환 UI

- 좌측 카테고리 패널(240px 고정)에서 8개 모드 중 1개 선택
- 선택된 모드의 Canvas가 중앙 편집 영역(flex:1.2)에 로드
- 우측 속성 패널(flex:1)에 선택된 요소의 Transform/색상/폰트 표시

## 모드별 Canvas 규격

### Mode 1: Board
- Canvas: 1920×1080 (Full HD 기준)
- 편집 요소:
  - 5장 커뮤니티 카드 슬롯 (Flop 3장 + Turn 1장 + River 1장)
  - 각 카드의 x/y/scale/rotation
  - 카드 뒷면/앞면 asset 참조
  - Reveal 애니메이션 트리거 (Rive State Machine 연결)

### Mode 2: Player
- Canvas: 480×270 (1좌석 전용)
- 편집 요소:
  - 이름 텍스트 (폰트, 크기, 색상, 정렬)
  - 스택 텍스트 (동일)
  - 국가 Flag 이미지 슬롯
  - 홀카드 2장 슬롯
  - 포지션 뱃지 (Dealer/SB/BB/UTG 색상은 BS-05-03 §시각 규격 참조, CC와 동일 체계)
  - action-glow 애니메이션 연결

### Mode 3: Dealer
- Canvas: 120×120
- 편집 요소:
  - Dealer button 이미지
  - 이동 애니메이션 경로 (좌석 간 이동 Rive animation)

### Mode 4: House
- Canvas: 1920×1080
- 편집 요소:
  - 배경 이미지 (Skin asset)
  - 사이드 배너 (좌/우 스폰서 영역)
  - Safe area 마커 (TV 오버스캔 고려)

### Mode 5: Logo
- Canvas: 512×512
- 편집 요소:
  - 대회 로고 슬롯
  - 스폰서 로고 슬롯 (최대 4개)
  - 로고 배치 그리드

### Mode 6: Ticker
- Canvas: 1920×64
- 편집 요소:
  - 스크롤 텍스트 소스 (static / 외부 RSS / API)
  - 스크롤 속도 (px/s)
  - 구분자 이미지
  - 폰트/색상

### Mode 7: SSD (Side Stake Display)
- Canvas: 400×240
- 편집 요소:
  - 사이드 팟 개수 동적 표시 (1~5개)
  - 승리금 애니메이션 (Rive)
  - "ALL-IN" 배지

### Mode 8: Action Clock
- Canvas: 240×240
- 편집 요소:
  - 카운트다운 숫자 폰트
  - 프로그레스 링 색상/두께
  - 타임 뱅크 표시 (추가 시간 인디케이터)
  - 만료 경고 애니메이션 (Rive, 10초 이하)

## 모드 간 공유 요소

- Skin 색상 팔레트 (8~16색)
- 공통 폰트 3~5종
- 공통 asset 폴더 (이미지/사운드)

## 변경 감지 및 자동 저장

- 10초마다 local draft 자동 저장 (`team4-cc/src/lib/features/graphic_editor/services/auto_save.dart`)
- Apply 시 Backend로 업로드하며 draft 제거
```

### 3. BS-08-02-skin-editor.md (신규)

```markdown
# BS-08-02 Skin Editor

> **참조**: team4-cc/ui-design/reference/skin-editor/EBS-Skin-Editor_v3.prd.md §Part II

## 레이아웃

WSOP 원본(PokerGFX WinForms 897×468)의 3열 Quasar QDialog를 Flutter로 재현:

```
┌──────────┬─────────────────────┬───────────────┐
│ 좌측     │ 중앙 (flex:1.2)      │ 우측 (flex:1) │
│ 240px    │                     │               │
│ 고정     │                     │               │
│          │ Canvas              │  Settings     │
│ Modes    │ (선택된 모드)         │  Panel        │
│ (8개)    │                     │               │
│          │                     │               │
│ Metadata │                     │               │
│ (5개)    │                     │               │
│          │                     │               │
│ Actions  │                     │               │
│ (6개)    │                     │               │
└──────────┴─────────────────────┴───────────────┘
```

## 좌측 패널

### Metadata (5개)
- Skin Name (Edit, max 40)
- Author (Edit, max 40)
- Version (Edit, semver)
- Created (ReadOnly)
- Modified (ReadOnly, 자동 갱신)

### Modes (8개)
BS-08-01 참조.

### Actions (6개)
- New Skin
- Open Skin (.gfskin)
- Save Draft (local)
- Apply (Backend 업로드)
- Export (.gfskin 다운로드)
- Revert (마지막 Apply 상태로)

## 중앙 Canvas

선택된 모드의 Canvas를 렌더링. Flutter `CustomPaint` + Rive `RiveAnimation`.

- Zoom: 25% / 50% / 100% / 200% / Fit
- Grid snap: 8px / 16px / 32px / Off
- Ruler: 상/좌측 눈금

## 우측 Settings Panel

### 선택된 요소의 속성 (WSOP 원본 99개 컨트롤 매핑)

| Category | 개수 | EBS 처리 |
|----------|:---:|---------|
| CheckBox | 58 | 가시성/활성 토글 (Visible, UseAnimation 등) |
| ComboBox | 48 | 폰트/색상/정렬/asset 선택 |
| Button | 30 | Action 트리거 (Reset, Duplicate, Delete) |
| Spinner | 16 | 숫자 속성 (Size, Opacity, Padding) |
| Edit | 6 | 텍스트 속성 (Label, URL) |
| Slider | 2 | 연속값 (Scale, Volume) |

**총 160개 중 WSOP 원본의 비활성 58개(19%)는 EBS에서 제외**:
- 카메라/녹화/연출 19개
- Delay/Secure Mode 9개
- 외부 연동 (Stream Deck/ATEM/Decklink) 7개
- Twitch 5개
- 기타(태그/라이선스) 18개

EBS에서 사용하는 컨트롤: 약 **102개** (160 - 58 = 102)

### 상세 매핑

전체 컨트롤 매핑 표는 `team4-cc/ui-design/reference/skin-editor/EBS-Skin-Editor_v3.prd.md` §Part III에서 관리. BS-08은 **Category별 개수와 제외 정책**만 계약화한다.

## 파일 포맷

`.gfskin`:
- ZIP 아카이브
- `manifest.json` (metadata)
- `modes/{mode_name}.json` (각 모드 Canvas 정의)
- `assets/` (이미지, Rive .riv, 폰트)
```

### 4. BS-08-03-color-adjust.md (신규)

```markdown
# BS-08-03 Adjust Colours Modal

> **참조**: team4-cc/ui-design/reference/skin-editor/EBS-Skin-Editor_v3.prd.md §Color

## 진입

- 우측 Settings Panel에서 Color 속성 클릭 → Adjust Colours 모달 열림
- 키보드 단축키: 미지정

## 기능 3종

### 1. Hue Shift
- 슬라이더: -180° ~ +180°
- 대상: 선택된 요소의 모든 색상
- WYSIWYG 프리뷰: Canvas 실시간 갱신

### 2. Tint
- 색상 피커 + 강도 슬라이더 (0~100%)
- 대상: 선택된 요소의 기본 색상 위에 오버레이
- Blend mode: multiply / screen / overlay 3종

### 3. 3-Color Replace
- From 색상 3개 × To 색상 3개 매핑
- Tolerance 슬라이더 (0~100, 유사도 기준)
- 대상: 이미지 asset의 특정 색상만 교체 (Flag, Logo 등)

## UI

- 모달 크기: 560×480
- 좌측 컨트롤, 우측 프리뷰 (Canvas 미니어처)
- Apply / Cancel / Reset 버튼

## 접근성

- WCAG 2.1 AA 대비율 자동 검증
- 저대비 경고 표시 (대비율 < 4.5:1)
```

### 5. BS-08-04-rive-import.md (신규)

```markdown
# BS-08-04 Rive Animation Import

> **참조**: team4-cc/qa/graphic-editor/QA-GE-02-checklist.md §GE-03-02 (현재 미구현)

## 배경

team4-cc QA 감사에서 **"Rive .riv 파일 로딩 미구현 — Import 버튼만 있음"**이
CRITICAL 미이행 항목으로 식별되었다(`qa/graphic-editor/QA-GE-02-checklist.md` §GE-03-02).
본 BS-08-04는 이 기능의 계약을 확정한다.

## Import 워크플로우

```
[Import .riv] 버튼 클릭
  │
  ├─ 파일 선택 다이얼로그
  │   └─ 확장자 필터: *.riv
  │
  ├─ 파일 로드 (Rive runtime)
  │   ├─ 성공: State Machine 목록 추출 → 선택 UI 표시
  │   └─ 실패: "파일 파싱 실패" 토스트
  │
  ├─ State Machine 선택
  │   └─ 사용할 State Machine 1개 선택
  │
  ├─ Input 매핑
  │   └─ Rive Input (Number/Boolean/Trigger)을 EBS 이벤트와 매핑
  │       예: Rive `bet_amount` Input ← EBS `SendPlayerBet.amount`
  │
  └─ Skin에 저장
      └─ assets/animations/{name}.riv 에 사본 저장
      └─ modes/{mode_name}.json 에 reference 추가
```

## State Machine Input 타입

- **Number**: 숫자 값 (0~100, 0~∞)
- **Boolean**: true/false 토글
- **Trigger**: 일회성 이벤트 발동 (FOLD, ALL-IN)

## 프리뷰

- 중앙 Canvas에서 State Machine을 실시간 재생
- 우측 Panel에 Input 컨트롤 (슬라이더/토글/버튼) 배치
- Admin이 값 조정하며 애니메이션 동작 확인

## Export

- 편집한 Rive State Machine은 원본 .riv 파일을 수정하지 않음
- Skin에 저장 시 원본 .riv + EBS 매핑 JSON 별도

## 라이선스

- Rive 사용 라이선스 명시 필수 (Skin manifest에 기록)
- 상업적 사용 가능 확인
```

### 6. BS-08-05-preview-apply.md (신규)

```markdown
# BS-08-05 Preview / Apply Workflow

## Preview

### Local Draft
- 편집 중인 상태는 `local draft`로 자동 저장 (BS-08-01 §자동 저장)
- 브라우저 종료 시 draft 유지 (다음 실행 시 복원)

### Live Preview
- Canvas 편집과 동시에 실시간 반영 (WYSIWYG)
- Rive 애니메이션은 State Machine 재생 (Input 슬라이더 제공)

### Broadcast Preview
- Admin이 `Broadcast Preview` 버튼 클릭 → 별도 Overlay Window 열림
- 실제 방송 Overlay와 동일 해상도 (1920×1080)로 미리보기
- 더미 게임 상태로 렌더링 (10좌석, 샘플 핸드, 팟 등)

## Apply

### 흐름

```
[Apply] 버튼 클릭
  │
  ├─ 경고 다이얼로그
  │   └─ "라이브 방송 Overlay가 교체됩니다. 계속하시겠습니까?"
  │
  ├─ Backend 업로드
  │   ├─ POST /skins (신규) 또는 PUT /skins/{id} (덮어쓰기)
  │   ├─ payload: .gfskin ZIP 파일
  │   └─ 응답: { skin_id, version }
  │
  ├─ Active Skin 교체
  │   ├─ PATCH /configs/active_skin { skin_id }
  │   └─ Backend가 WebSocket `SkinChanged` 이벤트 발행
  │
  ├─ 모든 Overlay 인스턴스 동기화
  │   ├─ Overlay 앱이 `SkinChanged` 수신
  │   ├─ 새 Skin asset 다운로드
  │   └─ 5초 페이드 트랜지션으로 교체
  │
  └─ Graphic Editor에서 "Applied ✓" 토스트
```

### Revert

- Apply 이력은 최대 10단계 보관
- `Revert` 버튼 → 이전 Apply 시점으로 Rollback
- 이전 skin_id로 `PATCH /configs/active_skin` 호출

## Lobby Settings 연동

- BS-03-settings의 Skin 목록은 Apply된 Skin들을 보여줌
- Admin은 Lobby에서 active Skin 전환 가능 (Graphic Editor 경유 없이)
- Graphic Editor는 **편집 전용**, Lobby Settings는 **목록/활성 관리**

## 참조

- BS-03-settings §Skin 목록
- API-01 §Skin 9개 API (POST/PUT/PATCH/GET/DELETE)
- API-05 §SkinChanged 이벤트
```

## Diff 초안

BS-08은 전체 신규 작성이므로 Diff는 "파일 생성"이다. 위 6개 파일 내용이 그대로 작성된다.

```diff
+++ contracts/specs/BS-08-graphic-editor/BS-08-00-overview.md (신규)
+++ contracts/specs/BS-08-graphic-editor/BS-08-01-modes.md (신규)
+++ contracts/specs/BS-08-graphic-editor/BS-08-02-skin-editor.md (신규)
+++ contracts/specs/BS-08-graphic-editor/BS-08-03-color-adjust.md (신규)
+++ contracts/specs/BS-08-graphic-editor/BS-08-04-rive-import.md (신규)
+++ contracts/specs/BS-08-graphic-editor/BS-08-05-preview-apply.md (신규)
```

## 영향 분석

### Team 1 (Lobby/Frontend)
- **영향**: 
  - BS-03 Settings의 Skin 목록 화면과 BS-08-05 Preview/Apply의 경계 합의 필요
  - Lobby에서 Graphic Editor를 Launch하는 경로 신설
- **예상 리뷰 시간**: 2시간

### Team 2 (Backend)
- **영향**:
  - Skin API 9개(`POST /skins`, `PUT /skins/{id}`, `PATCH /configs/active_skin`, etc.)가 이미 API-01에 존재하는지 확인
  - `SkinChanged` WebSocket 이벤트가 API-05에 있는지 확인 (없으면 Cross-reference CCR 필요)
- **예상 리뷰 시간**: 2시간

### Team 4 (self)
- **영향**:
  - BS-08 신규 문서 6개를 Conductor가 작성하는 동안 Team 4는 `team4-cc/src/lib/features/graphic_editor/` 하위 6개 서브모듈 스텁 생성
  - Rive runtime 패키지(`rive: ^0.13`) pubspec.yaml에 추가
  - .riv 파일 파싱/재생 구현 (현재 QA 감사에서 미구현 CRITICAL 항목)
- **예상 작업 시간**: 문서 리뷰 4시간 + 스텁 생성 6시간 + Rive 구현 20시간 = 약 30시간

### 마이그레이션
- 없음 (BS-08 신규)

## 대안 검토

### Option 1: BS-08 작성하지 않고 WSOP 원본 복사본만 유지
- **장점**: 계약 문서 증가 없음
- **단점**: 
  - Graphic Editor 구현자가 `team4-cc/ui-design/reference/skin-editor/` 복사본에 전적으로 의존
  - 계약 권위 부재로 team1/team2와의 경계 분쟁 시 근거 없음
  - 다른 BS(01~07)과의 일관성 파괴 (BS-05는 CC, BS-07은 Overlay, Graphic Editor만 공백)
- **채택**: ❌

### Option 2: BS-08 전문 작성 (본 제안)
- **장점**: 
  - Team 4의 3개 화면 모두 계약에 반영됨
  - 8모드 구조로 PokerGFX 역설계 자산 활용
  - Rive 미구현 CRITICAL 해결 경로 확보
- **단점**: 6개 파일 신규 작성 비용
- **채택**: ✅

### Option 3: BS-08 최소 작성 (Overview만)
- **장점**: 초기 부담 최소화
- **단점**: 8모드/Skin Editor/Color Adjust 상세가 누락되어 여전히 구현 혼란
- **채택**: ❌

## 검증 방법

### 1. 계약 완결성
- [ ] BS-08-00~05 6개 파일 모두 작성됨
- [ ] BS-00의 "앱 아키텍처" 용어표에 "Graphic Editor" 추가됨
- [ ] team4-cc/CLAUDE.md의 "3개 화면" 표에서 Graphic Editor가 BS-08 참조로 링크됨

### 2. 참조 일관성
- [ ] BS-08이 BS-07(Overlay), BS-03(Settings)와 양방향 참조
- [ ] API-01의 Skin 9개 API와 BS-08-05 Apply 흐름이 1:1 매핑
- [ ] WSOP 원본 `EBS-Skin-Editor_v3.prd.md`의 99개 컨트롤이 BS-08-02 Category 표와 일치

### 3. 구현 가능성
- [ ] Team 4가 `team4-cc/src/lib/features/graphic_editor/` 6개 서브모듈 스텁 생성 가능
- [ ] Rive runtime 패키지 설치 및 .riv 파싱 PoC 통과
- [ ] 현재 QA-GE-02-checklist의 CRITICAL 항목(Rive 미구현) 해소 경로 확인

### 4. WSOP 원본 대조
- [ ] 8모드: Board/Player/Dealer/House/Logo/Ticker/SSD/Action Clock 모두 반영
- [ ] Skin Editor 99개 컨트롤 Category: CheckBox 58, ComboBox 48, Button 30, Spinner 16, Edit 6, Slider 2 일치
- [ ] Adjust Colours 3기능: Hue / Tint / 3-Color Replace 반영

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (Lobby Settings Skin 목록 경계)
- [ ] Team 2 기술 검토 (Skin API, SkinChanged 이벤트 존재 확인)
- [ ] Team 4 기술 검토 (Rive runtime 구현 가능성, QA-GE-02 CRITICAL 해소)
