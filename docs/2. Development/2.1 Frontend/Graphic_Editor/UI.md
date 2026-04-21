---
title: UI
owner: team1
tier: internal
legacy-id: UI-04
last-updated: 2026-04-15
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "UI-04 Graphic Editor UI 스펙 (46KB) 완결"
---
# UI-04 Graphic Editor — Lobby 허브 와이어프레임

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | CCR-011 APPLIED 기반 GE 허브 기획서. 3-Zone 레이아웃, rive-js 프리뷰, GEM-01~25 메타데이터 폼, Upload Dropzone, Activate 흐름, BS-08-04 RBAC gate |
| 2026-04-10 | routes drift fix | §2 라우터 메타의 route name 을 `graphic-editor-hub/detail` → `ge-hub/ge-detail` 로 교정. `src/router/routes.ts` + UI-A1 §2.1 SSOT 와 정합 |
| 2026-04-15 | Skin Editor 자산 참조 추가 | Lobby 헤더 독립 `[Graphic Editor]` 진입점 반영 (Round 2). References/skin-editor/ 의 세부 레이아웃 자산(ebs-ui-layout-anatomy.md / EBS-Skin-Editor_v3.prd.md / 17 HTML 목업 / 8 컴포넌트 / 디자인 토큰) 을 상단 포인터로 연결. team1 발신. |
| 2026-04-21 | Flutter Desktop 전환 1차 | Foundation §5.1 결정 반영. 3-Zone 레이아웃 서술 Flutter 로 재작성 (q-page+q-splitter → Scaffold+multi_split_view), Zone 1/2 컴포넌트 선언 Flutter 로 교체, GEM 표 5개의 "Quasar 컴포넌트" 열 헤더 "Flutter widget" 으로 전환. 개별 q-* 셀 다수 잔존 — Quasar↔Flutter 매핑표는 `docs/4. Operations/Plans/Lobby_Flutter_Stack_Doc_Migration_Plan_2026-04-21.md §3` 참조. 세부 컴포넌트 교체는 team1 후속 PR. |

---

## 0. 이 문서를 읽는 법

이 문서는 Team 1 frontend Lobby 헤더 독립 `[Graphic Editor]` 진입점에서 렌더링되는 **Graphic Editor 허브의 와이어프레임과 상호작용 스펙**을 정의한다. 계약(BS-08-*, API-07, DATA-07)은 변경하지 않고 참조한다.

### 0.1 세부 레이아웃 설계 자산 (2026-04-15 추가)

이미 완성된 **Skin Editor 설계 자산** 이 `References/skin-editor/` 에 있다. 본 문서의 §3~§5 를 구현할 때 아래 자산을 우선 참조한다.

| 자산 | 경로 | 용도 |
|------|------|------|
| **전술 레이아웃 (L1)** | `References/skin-editor/ebs-ui-layout-anatomy.md` | SkinEditorDialog 컴포넌트 트리 (Element 01~61), T1/T2/T3 배치, GE A/B/C 적응형 패턴 |
| **최신 정본 PRD (v3.0)** | `References/skin-editor/EBS-Skin-Editor_v3.prd.md` | Element ID (S-##/GE-##), 187 필드 매핑, 8 GE 모드 상세 |
| **설계 원칙** | `References/skin-editor/ebs-ui-design-strategy.md` | WYSIWYG-First · Progressive Disclosure · Spatial Consistency · Density Balance · PokerGFX Parity |
| **구현 계획** | `References/skin-editor/ebs-ui-design-plan.md` | 8 공유 컴포넌트 (`EbsSectionHeader`, `EbsSlider`, `EbsColorPicker` 등), 폴더 구조, `quasar.variables.scss` 디자인 토큰 |
| **18 에디터 벤치마크** | `References/skin-editor/prd-skin-editor-layout-references.prd.md` | Figma UI3, Unity Inspector, vMix GT Designer 등 7 분석 기준 |
| **CSS 추출** | `References/skin-editor/data/layout-css-extraction.md` | Grid/Flex 치수·여백·색 명세 |
| **HTML 목업 (Skin Editor)** | `References/skin-editor/mockups/ebs-skin-editor.html` | 메인 화면 인터랙티브 (29KB) |
| **HTML 목업 (GE 8 모드)** | `References/skin-editor/mockups/ebs-ge-{board,field,blinds,strip,history,leaderboard,player,outs}.html` | 각 모드별 인터랙티브 (30~33KB) |
| **스크린샷** | `References/skin-editor/images/ebs-*.png` (50+) | 클린/주석(annotated) 버전 |
| **레이아웃 밸런스 솔루션** | `References/skin-editor/skin-editor-layout-balance-solutions.md` | 6 CSS/컴포넌트 솔루션 (높이 균형, flex-grow, 접이식 T1/T2/T3) |
| **UI 트리 JSON** | `References/skin-editor/data/skin-editor-ui-tree.json` | Element 부모-자식 관계 프로그래매틱 |

### 0.2 8 GE 모드 목업 경로 표

| 모드 | Element ID | HTML 목업 |
|------|-----------|----------|
| Board | GE-01 | `mockups/ebs-ge-board.html` |
| Field | GE-02 | `mockups/ebs-ge-field.html` |
| Blinds | GE-03 | `mockups/ebs-ge-blinds.html` (+ `ebs-ge-blinds-ante.html`) |
| Strip (Score Strip) | GE-04 | `mockups/ebs-ge-strip.html` |
| History | GE-05 | `mockups/ebs-ge-history.html` (+ footer·repeat 변형) |
| Leaderboard | GE-06 | `mockups/ebs-ge-leaderboard.html` (+ repeat·footer 변형) |
| Player | GE-07 | `mockups/ebs-ge-player.html` (+ compact·vertical 변형) |
| Outs | GE-08 | `mockups/ebs-ge-outs.html` |

### 0.3 구현 순서 (Phase 1~4)

`ebs-ui-design-plan.md §6 Phase 로드맵` 을 따른다:
1. Phase 1: `SkinMetadata.vue` (Element 01~05, 상단 전폭)
2. Phase 2: `ElementGrid.vue` (06, 좌상) + `ColourAdjust.vue` (27~30, 좌중하)
3. Phase 3: `VisualSettings.vue` (07~20, 중앙) + `BehaviourSettings.vue` (31~61, 우측)
4. Phase 4: GE 8 모드 (`GfxEditorBase.vue` + 패턴 A/B/C)

### 0.4 이 문서와 Skin Editor 자산의 역할 분담

| 주제 | 본 문서 (`UI.md`) | Skin Editor 자산 |
|------|-----------------|-----------------|
| 3-Zone 레이아웃 큰 그림 | ✓ | ✓ (상세는 자산) |
| Element 01~61 좌표·치수 | 포인터만 | ✓ (`ebs-ui-layout-anatomy.md`) |
| 디자인 토큰 (색·폰트·간격) | 포인터만 | ✓ (`ebs-ui-design-plan.md §3`) |
| 적응형 패턴 A/B/C | 포인터만 | ✓ |
| 상태 머신 (Upload/Activate FSM) | ✓ (§4 Use Case Flows, §8 Activate) | — |
| RBAC gate | ✓ (§9) | — |
| 라우터·Vue 컴포넌트 구조 | ✓ (§2) + `../Engineering.md §2.1` | — |

본 문서는 **허브 차원 와이어프레임 + 상호작용 스펙** 만 유지. Element 단위 세부는 Skin Editor 자산에서 이관하지 않고 참조.

---

실제 Vue 컴포넌트 구조/stores/router 는 `UI-A1-architecture.md §2.1 (route)`, `§3.2.4 (useGeStore)`, `§5 (WS client)` 에 정의되어 있으며, 본 문서는 그 위에서 **화면이 어떻게 보이고 동작하는지**만 다룬다.

| 당신이 | 참조할 곳 |
|--------|-----------|
| 3-Zone 레이아웃을 보려 한다 | §3 화면 레이아웃 |
| 업로드부터 Activate 까지 흐름을 알고 싶다 | §4 Use Case Flows |
| 메타데이터 폼 필드를 구현한다 | §5 Metadata Form |
| Drag&drop 업로드를 구현한다 | §6 Upload Dropzone |
| rive-js 프리뷰를 삽입한다 | §7 rive-js Preview |
| Activate 버튼 상태 머신을 구현한다 | §8 Activate 흐름 |
| Admin/Operator/Viewer 를 분기한다 | §9 RBAC gate |
| 에러/로딩/빈 상태 UI 를 만든다 | §10 에러/로딩/빈 상태 |
| 이 문서가 어떤 CCR 에 근거하는지 확인한다 | §11 관련 CCR |

---

## 1. 개요

CCR-011 `ge-ownership-move` APPLIED 로 Graphic Editor 허브의 소유권이 Team 4 (Flutter CC) 에서 **Team 1 (Quasar Lobby)** 로 이관되었다. 그 이전의 "8모드 99컨트롤 편집" 구상은 Rive 공식 에디터와 기능이 중복되어 YAGNI 사유로 폐기되었고, 대신 Team 1 GE 는 **업로드·검증·메타데이터 편집·Activate** 의 4개 책임만 가진다. 시각적 애니메이션/키프레임/색상 조정/Artboard 편집은 디자이너가 Rive 공식 에디터에서 직접 수행한 뒤 `.gfskin` ZIP 으로 패키징해 업로드한다.

본 허브의 범위 (BS-08-00 §1 준수):

| In-scope | Out-of-scope |
|----------|-------------|
| `.gfskin` ZIP 업로드 + 검증 | Rive Artboard 편집 |
| 로컬 rive-js 프리뷰 렌더링 | Animation keyframe 조정 |
| `skin.json` 메타데이터 PATCH (GEM-01~25) | Transform/색상 adjust UI |
| `PUT /skins/{id}/activate` + WS `skin_updated` broadcast | 8모드 99컨트롤 편집기 |
| Admin/Operator/Viewer RBAC gate | Overlay 전환 애니메이션 설계 |
| 스킨 Delete (비활성만) | Overlay 런타임 재렌더 (Team 4 CC/Overlay 담당) |

참조 계약:

- `../specs/BS-08-graphic-editor/BS-08-00-overview.md` — 역할·페르소나·use case
- `../specs/BS-08-graphic-editor/BS-08-01-import-flow.md` — 업로드 FSM (GEI-01~08)
- `../specs/BS-08-graphic-editor/BS-08-02-metadata-editing.md` — 편집 FSM + PATCH (GEM-01~25)
- `../specs/BS-08-graphic-editor/BS-08-03-activate-broadcast.md` — Activate FSM + WS (GEA-01~06)
- `../specs/BS-08-graphic-editor/BS-08-04-rbac-guards.md` — RBAC gate (GER-01~05)
- `contracts/api/API-07-graphic-editor.md` — 8 엔드포인트
- `contracts/data/DATA-07-gfskin-schema.md` — `.gfskin` ZIP 포맷 + JSON Schema
- CCR-011, CCR-012, CCR-013, CCR-014, CCR-015, CCR-025 (APPLIED)

---

## 2. 라우팅

UI-A1 §2.1 router tree 와 정합한다.

| 경로 | 컴포넌트 | 목적 |
|------|----------|------|
| `/lobby/graphic-editor` | `GraphicEditorHubPage.vue` | 허브 (리스트 + detail pane 병치) |
| `/lobby/graphic-editor/:skinId` | `GraphicEditorDetailPage.vue` | 직접 링크 진입 (selectedSkin 으로 초기화) |

라우터 메타:

```
{
  path: 'lobby/graphic-editor',
  name: 'ge-hub',
  component: () => import('pages/graphic-editor/GraphicEditorHubPage.vue'),
  meta: {
    requiresAuth: true,
    requiredPermission: 'GraphicEditor:Read'
  }
},
{
  path: 'lobby/graphic-editor/:skinId',
  name: 'ge-detail',
  component: () => import('pages/graphic-editor/GraphicEditorDetailPage.vue'),
  meta: {
    requiresAuth: true,
    requiredPermission: 'GraphicEditor:Read'
  }
}
```

라우팅 동작:

- Viewer 가 `/lobby/graphic-editor` 로 직접 접근 → `beforeEnter` 가드가 `/lobby/unauthorized` 로 redirect (BS-08-04 §2.1, GER-03).
- `/:skinId` 직접 링크 진입 시 허브 페이지의 `selectedSkinId` 를 url param 으로 초기화하고, 리스트는 동일하게 표시한다. 즉 단일 SPA 뷰 위에서 deep-link 만 제공한다.
- 허브 → detail 내부 네비게이션은 `router.replace` 로 URL 만 갱신 (리스트/프리뷰 마운트 유지).

---

## 3. 화면 레이아웃 (3-Zone 와이어프레임)

BS-08-00 §4 의 3-Zone 구조를 Flutter `Scaffold` + `multi_split_view` 패키지 (또는 `Row` + `ResizableWidget`) 로 구현한다. 한 줄 65자 이내, mermaid 미사용.

```
┌───────────────────────────────────────────────────────────────┐
│ Header  Graphic Editor                                       │
│ [⬆ Upload .gfskin] [🔍 검색 _______]  Filter: [Active ▼]    │
├────────────────────┬──────────────────────────────────────────┤
│ Zone 2: Skin List  │ Zone 3: Detail Pane                      │
│ (q-list, 30%)      │ (70%)                                    │
│                    │ ┌─ Preview (rive-js 640×480) ──────────┐ │
│ ● classic-v2  v3   │ │                                      │ │
│   Admin · 12 MB    │ │          [canvas]                    │ │
│                    │ │                                      │ │
│ ○ bracelet-wsop    │ │  [▶ Play] [⏸ Pause] [↺ Reset]       │ │
│   Admin · 18 MB    │ └──────────────────────────────────────┘ │
│                    │ ┌─ Metadata Form (GEM-01 ~ GEM-25) ───┐ │
│ ○ cyprus-24   v1   │ │ Identity                             │ │
│   Alice · 9 MB     │ │   skin_name  [ classic-v2 _______ ]  │ │
│                    │ │   version    [ 1.3.0 ____________ ]  │ │
│ ▶ playground  v2   │ │   author     [ BRACELET STUDIO __ ]  │ │
│   Admin · 14 MB    │ │                                      │ │
│                    │ │ Resolution / Background              │ │
│                    │ │   resolution [ 1920×1080 ▼ ]         │ │
│                    │ │   bg.type    [ color ▼ ]             │ │
│                    │ │   bg.color   [ ■ #101820 ]           │ │
│                    │ │                                      │ │
│                    │ │ Colors (9)                           │ │
│                    │ │   background       [ ■ #101820 ]     │ │
│                    │ │   text_primary     [ ■ #FFFFFF ]     │ │
│                    │ │   text_secondary   [ ■ #C0C0C0 ]     │ │
│                    │ │   badge_check      [ ■ #00FF88 ]     │ │
│                    │ │   badge_fold       [ ■ #888888 ]     │ │
│                    │ │   badge_bet        [ ■ #FFAA00 ]     │ │
│                    │ │   badge_call       [ ■ #44AAFF ]     │ │
│                    │ │   badge_allin      [ ■ #FF3355 ]     │ │
│                    │ │   (+ 1 optional)                     │ │
│                    │ │                                      │ │
│                    │ │ Fonts (6 keys)                       │ │
│                    │ │   pot.family   [ Inter ▼ ]           │ │
│                    │ │   pot.size     [ 48 ___  ] px        │ │
│                    │ │   pot.weight   [ bold ▼ ]            │ │
│                    │ │   chip.*       (family/size/weight)  │ │
│                    │ │                                      │ │
│                    │ │ Animations (5 durations)             │ │
│                    │ │   card_fade            [ 250 ] ms    │ │
│                    │ │   board_slide          [ 400 ] ms    │ │
│                    │ │   board_stagger_delay  [  80 ] ms    │ │
│                    │ │   glint_sequence       [ 900 ] ms    │ │
│                    │ │   reset                [ 300 ] ms    │ │
│                    │ └──────────────────────────────────────┘ │
│                    │ [💾 Save Metadata] [🚀 Activate]        │
│                    │ [↩ Revert] [🗑 Delete]                  │
└────────────────────┴──────────────────────────────────────────┘
```

### 3.1 Zone 설명

**Zone 1 — Header (상단 고정)**

- Flutter widget: `AppBar` / `Container` (toolbar) + 자식 `ElevatedButton`/`TextButton`, `TextField`, `DropdownButton`.
- "Upload .gfskin" 버튼: Admin 에게만 노출 (GER-01). 클릭 시 `q-file` 트리거 또는 dropzone 오버레이 (§6).
- 검색 바: `TextField` `debounce="300"`, `clearable`. skin_name + version 에 대해 client-side filter.
- 필터: `DropdownButton` `options=[All, Active, Inactive]`, 기본값 `All`.

**Zone 2 — Skin List (좌측 30%)**

- Flutter widget: `ListView.separated(separatorBuilder: Divider)` → `InkWell(child: ListTile)` 반복.
- 활성 스킨은 `● ` (녹색 `Icon(Icons.circle, color: Colors.green)`) 아이콘. 비활성은 `○` (회색 outline).
- 행 레이아웃: `ListTile(leading: ...)` (상태 아이콘) + `ListTile` section (skin_name + version) + `Text(..., style: TextStyle(fontSize: 12))` (caption) (author · 파일 크기).
- 선택 행은 `active` prop → Quasar primary background.
- 선택 변경 → `useGeStore.selectedSkinId` 업데이트 → Zone 3 리렌더.
- 리스트 하단: `ListView.builder` + `ScrollController.addListener` (pagination) (페이지네이션, BS-08-00 §4 Left Zone 언급). 초기 fetch: `GET /api/v1/skins?limit=50`.

**Zone 3 — Detail Pane (우측 70%)**

- 상단 50%: rive-js 프리뷰 canvas (§7)
- 하단 40%: 메타데이터 폼 (§5, `Form` + `Card` 섹션 분할)
- 하단 10%: 액션 버튼 영역 (sticky footer). Admin 만 버튼 노출 (Operator 는 대체 배너, §9).

### 3.2 반응형

| 뷰포트 | 레이아웃 |
|--------|----------|
| ≥ 1280 px | 3-Zone 병치 (위 다이어그램) |
| 960 ~ 1279 px | `multi_split_view` 또는 `Row` + `ResizableWidget` 비율 40:60, 프리뷰 canvas 540×405 축소 |
| < 960 px | Zone 2 / Zone 3 를 `TabBar` 로 분리. "List" 탭 ↔ "Detail" 탭 |

UI-00 §8 반응형 브레이크포인트 준수.

---

## 4. Use Case Flows (ASCII flow)

3개 주요 플로우는 BS-08-00 §3 의 use case 3.1/3.2/3.3 를 UI 관점으로 확장한다.

### 4.1 신규 스킨 업로드 (Designer → Admin)

```
Designer: .riv 작성 (Rive 공식 에디터, 외부 툴)
  ↓
Designer: .gfskin ZIP 패키징
  (skin.json + skin.riv [+ cards/ + assets/])
  ↓
Admin: Lobby 사이드바 → Graphic Editor 메뉴
  ↓
Quasar route → GraphicEditorHubPage.vue
  ↓
Admin: Header [⬆ Upload .gfskin] 클릭
  ↓
Zone 3 위에 UploadDropzone overlay 표시
  ↓
Admin: 파일 드래그 또는 클릭으로 .gfskin 선택
  ↓
useGeStore.uploadSkin(file)  (BS-08-01 FSM 시작)
  ↓
┌─ Client validation (q-linear-progress 4단계) ──┐
│ 1/4 validating_zip    (jszip)                  │
│ 2/4 parsing_json      (UTF-8 + JSON.parse)     │
│ 3/4 validating_schema (ajv + DATA-07)          │
│ 4/4 parsing_rive      (@rive-app/canvas)       │
└─────────────────────────────────────────────────┘
  ↓  OK
previewing : rive-js canvas 렌더링 (§7)
  ↓  Admin 클릭 [Upload 확정]
POST /api/v1/skins  (multipart + Idempotency-Key)
  ├→ 201 Created → saved
  ├→ 409 Conflict (idem 재사용) → 안내 토스트 + saved
  ├→ 422 Unprocessable → ValidationError 목록
  └→ 413 Payload Too Large → "50 MB 초과" 에러
  ↓  saved
useGeStore.skins 배열에 append
  ↓
Zone 2 리스트 자동 선택 → Zone 3 detail pane 초기화
  ↓
Admin: 필요 시 Metadata 편집 후 [💾 Save Metadata]
```

### 4.2 스킨 Activate (Admin)

```
Admin: Zone 2 에서 스킨 선택 → Zone 3 [🚀 Activate] 클릭
  ↓
useGeStore.activateSkin(id)
  ↓
GET /api/v1/game-state   (BS-08-03 §2.2 GameState 가드)
  ├→ state = "IDLE" → confirming (작은 confirm dialog)
  └→ state = "RUNNING" → warning_dialog (q-dialog)
       제목: "방송 진행 중입니다"
       본문: "Table {id} Hand {hand_id} 진행 중.
              스킨 교체 시 시청자에게 시각 단절 발생.
              핸드 종료 후 Activate 를 권장합니다."
       [취소] or [강제 Activate]
         ├→ 취소 → ready
         └→ 강제 Activate → confirming
  ↓
PUT /api/v1/skins/{id}/activate
  Headers:
    If-Match: W/"{etag}"
    X-Game-State: IDLE (또는 override 후 IDLE 강제)
    Idempotency-Key: {uuid4}
  ↓
  ├→ 201 { active_skin_id, seq, broadcasted_at }
  │     ↓
  │   broadcasting (useGeStore.activationState)
  │     ↓
  │   WS 수신: { type: "skin_updated", seq, payload }
  │     ↓
  │   useGeStore.applyRemoteSkinUpdate(payload)
  │     ↓
  │   Zone 2 의 ● 아이콘이 새 스킨으로 이동
  │     ↓
  │   activated → $q.notify({ type: 'positive', msg: 'Activated' })
  │
  ├→ 412 Precondition Failed (GEA-03)
  │     ↓
  │   conflict_refetch : q-dialog
  │     "다른 사용자가 먼저 변경했습니다. 최신 상태로 새로고침할까요?"
  │     [다시 시도] [취소]
  │     → GET /skins/{id} 로 refetch → 재시도
  │
  └→ 409 Conflict (GameState mismatch)
        ↓
      Warning 헤더 파싱 → 경고 다이얼로그 재표시
```

### 4.3 Metadata 편집 / Revert / Delete

```
Admin: 스킨 선택 → Detail pane 폼 필드 수정
  ↓
useGeStore.editMetadata(path, value)   (metadataDirty=true)
  ↓
ajv 실시간 검증 (per keystroke)
  ├→ valid → 필드 border 정상
  └→ invalid → 필드 하단 에러 + Save 비활성화
  ↓
  [💾 Save Metadata] 클릭
  ↓
PATCH /api/v1/skins/{id}/metadata
  Content-Type: application/merge-patch+json
  If-Match: W/"{etag}"
  body: { ... (changed fields only) }
  ↓
  ├→ 200 OK → metadataDirty=false, new etag 저장
  ├→ 412 → conflict_refetch
  └→ 422 → field-level 에러 표시

Revert:
  dirty=true 상태에서 [↩ Revert] 클릭
  ↓
  q-dialog 확인: "변경사항을 취소할까요?"
  ↓
  useGeStore.metadata = 마지막 저장 스냅샷
  metadataDirty=false

Delete:
  비활성 스킨에서만 [🗑 Delete] 버튼 활성화
  (활성 스킨은 disabled + tooltip "활성 스킨은 삭제할 수 없습니다")
  ↓
  q-dialog 확인: "'{skin_name}' 을 삭제합니다. 되돌릴 수 없습니다."
  ↓
  DELETE /api/v1/skins/{id}  (If-Match)
  ↓
  ├→ 204 → 리스트에서 제거, 선택 해제
  └→ 409 → "활성 스킨은 삭제할 수 없습니다" 에러
```

---

## 5. Metadata Form 필드 (GEM-01 ~ GEM-25)

본 섹션은 `BS-08-02-metadata-editing.md` + `DATA-07-gfskin-schema.md §3` 의 편집 매트릭스를 **완전 열거**한다. 필드 수와 GEM 범위는 계약 SSOT 인 DATA-07 §3 을 따른다 (Skin 식별 3 + 해상도/배경 2 + 색상 9 + 폰트 6 + 애니메이션 5 = 25).

### 5.1 Section A — Skin 식별 (GEM-01 ~ GEM-03)

| ID | skin.json path | Flutter widget | 제약 | 예시 |
|----|----------------|------------------|------|------|
| GEM-01 | `skin_name` | `q-input outlined dense` | `minLength=1, maxLength=40`, 필수 | "classic-v2" |
| GEM-02 | `version` | `q-input outlined dense` | `pattern=^\d+\.\d+\.\d+$` (semver), 필수 | "1.3.0" |
| GEM-03 | `author` | `q-input outlined dense` | `maxLength=80`, 선택 | "BRACELET STUDIO" |

섹션 헤더: `q-card-section` 상단 `q-item-label overline` = "Identity".

### 5.2 Section B — 해상도 / 배경 (GEM-04 ~ GEM-05)

| ID | skin.json path | Flutter widget | 제약 | 예시 |
|----|----------------|------------------|------|------|
| GEM-04 | `resolution.width` + `.height` | `DropdownButton` (single dropdown, `emit-value map-options`) | enum 쌍: {1920×1080, 2560×1440, 3840×2160}, 필수 | "1920 × 1080" |
| GEM-05 | `background.type` / `.color` / `.chromakey_color` / `.file` | `DropdownButton` (type) + 조건부 `q-color` (popup) + `q-file` (image 업로드) | `type ∈ {image,color,chromakey}`, color `#hex6` | type=color, color="#101820" |

**UI 규칙 (GEM-04)**:

- `resolution` 은 width/height 두 필드를 결합한 **단일 드롭다운** 으로 표시. 사용자가 "1920 × 1080" 을 선택하면 내부적으로 `{width:1920, height:1080}` 으로 저장.
- 옵션 변경 시 Zone 3 rive-js canvas 의 aspect ratio 도 즉시 변경 (프리뷰 동기화, BS-08-02 §5).

**UI 규칙 (GEM-05)**:

- `background.type` 이 `color` 일 때만 `q-color` picker 활성화.
- `chromakey` 일 때 `chromakey_color` picker 활성화.
- `image` 일 때 `q-file accept="image/*"` 업로드 위젯 표시 (파일은 ZIP 내 경로로 저장되므로 실제 업로드는 `.gfskin` 재패키징 필요 — BS-08-02 §1 "편집 불가" 항목에 해당할 가능성이 있어 임시로 경로 입력만 허용. spec-gap 후보).

### 5.3 Section C — Colors (GEM-06 ~ GEM-14, 9 키)

DATA-07 `colors` required 배열 + optional 키를 포함해 총 9개.

| ID | skin.json path | Flutter widget | 제약 | 예시 |
|----|----------------|------------------|------|------|
| GEM-06 | `colors.background` | `q-color` (popup) + `q-input readonly` | `^#[0-9A-Fa-f]{6}$` | "#101820" |
| GEM-07 | `colors.text_primary` | 동일 | 동일 | "#FFFFFF" |
| GEM-08 | `colors.text_secondary` | 동일 | 동일 | "#C0C0C0" |
| GEM-09 | `colors.badge_check` | 동일 | 동일 | "#00FF88" |
| GEM-10 | `colors.badge_fold` | 동일 | 동일 | "#888888" |
| GEM-11 | `colors.badge_bet` | 동일 | 동일 | "#FFAA00" |
| GEM-12 | `colors.badge_call` | 동일 | 동일 | "#44AAFF" |
| GEM-13 | `colors.badge_allin` | 동일 | 동일 | "#FF3355" |
| GEM-14 | `colors.*` (1 optional key) | `TextField` (key 이름) + `q-color` (값) | additionalProperties | "badge_raise": "#FF00AA" |

**UI 규칙**:

- 각 컬러는 `q-field outlined` 내부에 좌측 색상 프리뷰 `q-avatar square color="{hex}"` + 우측 `TextField` (hex 문자열) + 우측 끝 `q-color` popup 트리거.
- GEM-14 optional slot: "+ Add color key" 버튼으로 추가 (최대 1개 UI 슬롯). additionalProperties 이므로 더 필요하면 JSON 편집 모드로 전환 (현재 범위 밖).
- 실시간 검증: hex 패턴 실패 시 `q-field error` 상태 + `error-message="hex 형식: #RRGGBB"`.
- 프리뷰 동기화 (BS-08-02 §5): 값 변경 시 Rive state machine 의 color input 에 전달 (`rive.setInputValue('badge_check_color', hex)`).

### 5.4 Section D — Fonts (GEM-15 ~ GEM-20, 6 키)

DATA-07 `fonts.*` 는 각 키마다 `{family, size, weight}` 3 필드. UI 에서는 2개 대표 폰트 키 (`pot`, `chip`) × 3 필드 = 6 GEM ID.

| ID | skin.json path | Flutter widget | 제약 | 예시 |
|----|----------------|------------------|------|------|
| GEM-15 | `fonts.pot.family` | `DropdownButton` | enum: {Inter, Roboto, Noto Sans, Oswald, JetBrains Mono, Custom...} | "Inter" |
| GEM-16 | `fonts.pot.size` | `q-input type="number"` + suffix `px` | integer, 8~96, 필수 | 48 |
| GEM-17 | `fonts.pot.weight` | `DropdownButton` | enum: {regular, bold, italic, bold-italic} | "bold" |
| GEM-18 | `fonts.chip.family` | 동일 | 동일 | "Roboto" |
| GEM-19 | `fonts.chip.size` | 동일 | 동일 | 32 |
| GEM-20 | `fonts.chip.weight` | 동일 | 동일 | "regular" |

**UI 규칙**:

- 각 폰트 키는 `q-card-section` 내부에 3 필드를 `row q-col-gutter-sm` 으로 배치 (family 가 50%, size 가 20%, weight 가 30%).
- Font family 드롭다운은 `q-select use-input input-debounce="200"` 로 자체 필터링 지원.
- 프리뷰 동기화: `@font-face` 동적 로드 후 Rive text run 업데이트 (BS-08-02 §5).

### 5.5 Section E — Animations (GEM-21 ~ GEM-25, 5 duration)

| ID | skin.json path | Flutter widget | 제약 | 예시 |
|----|----------------|------------------|------|------|
| GEM-21 | `animations.card_fade_duration_ms` | `q-slider` + `q-input type="number"` 병치 | integer, 0~5000, ms | 250 |
| GEM-22 | `animations.board_slide_duration_ms` | 동일 | 0~5000 | 400 |
| GEM-23 | `animations.board_stagger_delay_ms` | 동일 | 0~1000 | 80 |
| GEM-24 | `animations.glint_sequence_duration_ms` | 동일 | 0~5000 | 900 |
| GEM-25 | `animations.reset_duration_ms` | 동일 | 0~5000 | 300 |

**UI 규칙**:

- 각 row: `q-slider` (좌측 70%, `:min=0 :max=5000 :step=10 label-always`) + `q-input type="number"` (우측 30%, 양방향 bind) + suffix "ms".
- 프리뷰 동기화: Rive state machine 의 duration parameter 를 즉시 업데이트 (BS-08-02 §5) 해 사용자가 바로 시각 피드백을 얻을 수 있게 한다.

### 5.6 편집 불가 필드 (readonly)

다음 필드는 폼에 **disabled input** 으로 표시되어 조회만 가능하다 (DATA-07 §3):

- `created_at` (서버 자동, ISO-8601)
- `modified_at` (서버 자동)
- `seats[*]` (Rive artboard 소유, "Edit in Rive Editor" 안내 툴팁)
- `.riv` 파일 내부 구조 일체

### 5.7 Save / Revert 버튼 조건

| 조건 | Save 버튼 | Revert 버튼 |
|------|:---------:|:-----------:|
| `metadataDirty=false` | disabled | disabled |
| `metadataDirty=true` + 모든 필드 valid | enabled | enabled |
| `metadataDirty=true` + 하나 이상 invalid | disabled | enabled |
| `status=saving` | `loading` | disabled |

UI-00 §9 버튼 패턴 준수 (`q-btn unelevated color="primary"` Save, `TextButton` Revert).

---

## 6. Upload Dropzone

### 6.1 진입 방식

- Header `[⬆ Upload .gfskin]` 버튼 클릭 → Zone 3 위에 `q-dialog maximized` 로 dropzone overlay 표시.
- Drag target: 화면 중앙 대형 영역 `q-card flat bordered dashed`, 최소 높이 320 px.

### 6.2 와이어프레임

```
┌─────────────────────────────────────────────────────────┐
│ Upload .gfskin                                  [✕]    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│    ┌─────────────────────────────────────────────┐     │
│    │                                             │     │
│    │              ⬆                              │     │
│    │                                             │     │
│    │    여기로 .gfskin 파일을 드래그하거나       │     │
│    │        [파일 선택] 을 클릭하세요            │     │
│    │                                             │     │
│    │    허용: .gfskin only · 최대 50 MB          │     │
│    │                                             │     │
│    └─────────────────────────────────────────────┘     │
│                                                         │
│  ▰▰▰▰▰▰▰▰▱▱▱▱▱▱▱▱  3/4 Rive 파싱 중...               │
│                                                         │
│  [ ⚠ Error 발생 시 여기에 q-banner ]                    │
└─────────────────────────────────────────────────────────┘
                             [ 취소 ]  [ Upload 확정 ]
```

### 6.3 동작

- 드래그 앤 드롭: Vue `@dragover.prevent` + `@drop.prevent` 에서 `event.dataTransfer.files[0]` 를 `useGeStore.uploadSkin()` 으로 전달.
- 클릭 선택: `q-file accept=".gfskin" label="파일 선택"`. 브라우저는 `.gfskin` MIME 매칭이 없으므로 확장자 정규식으로 검증.
- 검증 진행: `q-linear-progress indeterminate` → 단계별 `stripe` 전환 + 하단 caption 텍스트.
  - `1/4 ZIP 검증 중`
  - `2/4 Schema 검증 중`
  - `3/4 Rive 파싱 중`
  - `4/4 프리뷰 생성 중`
- 실패 시: `q-banner rounded class="bg-negative text-white"` 최상단 표시. 첫 에러 path 로 스크롤 (CSS `scroll-margin-top`).
- 성공 시: overlay 를 닫지 않고 하단에 `[Upload 확정]` 버튼 활성화. 업로드 확정 후 POST → 성공 시 dialog close.
- 허용 확장자: `.gfskin` only. 드롭된 파일이 `.zip` 이면 "확장자를 `.gfskin` 으로 변경 후 다시 시도하세요" 경고.
- 최대 크기: 50 MB (BS-08-01 §3). 드롭 즉시 `file.size > 50 * 1024 * 1024` 검사 → 검증 단계 진입 전 차단.

### 6.4 접근성

- Dropzone 영역에 `role="button" tabindex="0"` 부여, `Enter`/`Space` 로 `q-file` 트리거.
- aria-live="polite" 영역에 진행 단계 caption 을 동기화 → 스크린리더가 "3 of 4, Rive 파싱 중" 읽어줌.
- 에러 banner 는 `role="alert"`.

---

## 7. rive-js Preview (`@rive-app/canvas`)

### 7.1 컴포넌트 구조

```
<RiveCanvasPreview
  :src="currentSkinRiveUrl"
  :state-machine="'Default'"
  :width="640"
  :height="480"
/>
```

컴포넌트 파일: `src/components/graphic-editor/RiveCanvasPreview.vue` (UI-A1 §1.2 폴더 규칙).

### 7.2 구현 요지

```typescript
import { Rive, Layout, Fit, Alignment } from '@rive-app/canvas';
import { onMounted, onBeforeUnmount, ref, watch } from 'vue';

const props = defineProps<{
  src: string | ArrayBuffer;
  stateMachine?: string;
  width?: number;
  height?: number;
}>();

const canvasRef = ref<HTMLCanvasElement | null>(null);
const rive = ref<Rive | null>(null);
const loading = ref(true);
const error = ref<string | null>(null);

const createRive = () => {
  if (!canvasRef.value) return;
  rive.value = new Rive({
    canvas: canvasRef.value,
    src: typeof props.src === 'string' ? props.src : undefined,
    buffer: props.src instanceof ArrayBuffer ? props.src : undefined,
    stateMachines: props.stateMachine ?? 'Default',
    autoplay: true,
    layout: new Layout({ fit: Fit.Contain, alignment: Alignment.Center }),
    onLoad: () => { loading.value = false; },
    onLoadError: (e) => { error.value = String(e); loading.value = false; }
  });
};

onMounted(createRive);
watch(() => props.src, () => { rive.value?.cleanup(); createRive(); });
onBeforeUnmount(() => rive.value?.cleanup());
```

### 7.3 재생 컨트롤

| 버튼 | 동작 |
|------|------|
| `[▶ Play]` | `rive.value?.play()` — 현재 state machine 재생 |
| `[⏸ Pause]` | `rive.value?.pause()` |
| `[↺ Reset]` | `rive.value?.reset()` + `play()` |

Quasar: `q-btn-group` 내부에 `q-btn flat dense icon="play_arrow"` 등.

### 7.4 상태 표시

| 상태 | UI |
|------|-----|
| `loading=true` | `q-skeleton type="rect"` 640×480 덮음 + caption "Rive 로드 중..." |
| `error != null` | `q-banner class="bg-negative text-white"` + [재시도] 버튼 + 상세 에러 접기 (`q-expansion-item`) |
| 정상 | canvas + play/pause/reset 컨트롤 표시 |

### 7.5 메모리 관리

- `onBeforeUnmount` 에서 반드시 `rive.value?.cleanup()` 호출 (WebGL context leak 방지).
- 스킨 선택 변경 시 기존 인스턴스 `cleanup` 후 새 인스턴스 생성.
- 프리뷰 canvas 는 Zone 3 상단에만 단 1개 유지 (동시에 여러 스킨 프리뷰 금지).

---

## 8. Activate 흐름 (상세)

BS-08-03 의 Activate FSM 을 `useGeStore.activationState` 로 구현하고, 각 상태마다 버튼 라벨/색/disabled 를 다르게 표시한다.

### 8.1 버튼 상태 머신

| activationState | 버튼 라벨 | 색상 | disabled | 로딩 스피너 |
|-----------------|-----------|------|:--------:|:----------:|
| `idle` | `🚀 Activate` | `primary` | ✗ | ✗ |
| `warning` | `🚀 Activate` | `warning` (주황) | ✗ | ✗ |
| `confirming` | `⏳ Confirming...` | `primary` | ✓ | ✓ |
| `activating` | `⏳ Activating...` | `primary` | ✓ | ✓ |
| `activated` | `✅ Activated` | `positive` | ✓ (2초) | ✗ |
| `error` | `⚠ Retry Activate` | `negative` | ✗ | ✗ |

구현: Quasar `q-btn :color="computedColor" :loading="isActivating" :disable="isDisabled"`.

### 8.2 GameState 가드 (BS-08-03 §2)

```
Activate 버튼 클릭
  ↓
GET /api/v1/game-state    (axios + caching=false)
  ↓
if (gameState === 'RUNNING'):
  activationState = 'warning'
  q-dialog 표시 (GEA-02):
    title: "방송 진행 중입니다"
    message: "Table {id} Hand {hand_id} 진행 중.
              스킨을 교체하면 시청자에게 급격한 시각 전환이
              발생합니다. 핸드 종료 후 Activate 를 권장합니다."
    ok: "강제 Activate"  (color=warning)
    cancel: "취소"
  ↓
  if user clicks 강제 Activate:
    X-Game-State = "IDLE" (override)
  else:
    activationState = 'idle', return
else:
  X-Game-State = "IDLE"
  confirm dialog 바로 스킵 가능 (또는 작은 confirm)
```

### 8.3 PUT 요청 헤더

```
Authorization: Bearer {admin_jwt}
If-Match: W/"{etag}"
X-Game-State: IDLE
Idempotency-Key: {crypto.randomUUID()}
```

- `If-Match`: `useGeStore.metadata.etag` 에서 읽어옴. 이전 GET 에서 저장.
- `Idempotency-Key`: 컴포넌트 마운트 시 1회 생성 → 사용자 취소·재시도 시 동일 키 재사용해 중복 Activate 방지 (UI-A1 §4.3 axios interceptor 규칙).

### 8.4 응답 처리

| 응답 | 클라이언트 동작 |
|------|-----------------|
| 201 | `activationState = 'broadcasting'` → WS `skin_updated` 대기 |
| 412 Precondition Failed (GEA-03) | q-dialog "다른 사용자가 먼저 변경했습니다. 새로고침 후 재시도할까요?" → GET `/skins/{id}` 로 refetch → 재시도 |
| 409 Conflict (GameState mismatch) | Warning 헤더 파싱 → 경고 다이얼로그 재표시 → `activationState = 'warning'` |
| 403 Forbidden | "Admin 권한이 필요합니다" 토스트 → `activationState = 'idle'` |
| 5xx | "서버 오류. 잠시 후 재시도하세요" 토스트 → `activationState = 'error'` |

### 8.5 WS Broadcast 처리 (BS-08-03 §4, CCR-015)

```
useWsStore 가 'skin_updated' 이벤트 수신
  ↓
seq 단조성 검증 (CCR-015):
  if event.seq <= lastSeq: drop (out-of-order)
  else: lastSeq = event.seq
  ↓
useGeStore.applyRemoteSkinUpdate(payload):
  - skins 배열에서 active flag 이동
  - Zone 2 의 ● 아이콘이 새 스킨으로 이동
  - 내가 방금 activate 한 스킨이면 activationState = 'activated'
  - $q.notify({ type: 'positive', message: 'Activated', timeout: 2000 })
  - 2초 후 activationState = 'idle'
```

WS 수신이 2초 안에 오지 않으면 (GEA-06 목표 미달), `activationState = 'error'` + "Broadcast 수신 지연 — 리스트를 수동 새로고침하세요" 경고.

### 8.6 Replay (CCR-015)

WS 재연결 시 `useWsStore` 가 `GET /api/v1/events/replay?from_seq={lastSeq}&channel=cc_event` 호출 → 놓친 `skin_updated` 이벤트를 순서대로 재생. `useGeStore` 는 동일한 `applyRemoteSkinUpdate` 로 처리한다.

---

## 9. RBAC gate

BS-08-04 §1 행동 매트릭스를 UI 에 매핑한다. UI gate (버튼 숨김) + 라우터 가드 + API 서버측 재검증의 3중 가드.

### 9.1 역할 × 행동 매트릭스 (UI 관점)

| 행동 | Admin | Operator | Viewer |
|------|:-----:|:--------:|:------:|
| Lobby 사이드바 "Graphic Editor" 메뉴 노출 | ✓ | ✓ | ✗ |
| `/lobby/graphic-editor` 라우트 진입 | ✓ | ✓ | ✗ (redirect) |
| Zone 2 스킨 리스트 조회 | ✓ | ✓ | — |
| Zone 3 rive-js 프리뷰 | ✓ | ✓ (비인터랙티브) | — |
| Zone 3 Metadata 필드 조회 | ✓ | ✓ (disabled) | — |
| Header `[⬆ Upload]` 버튼 | ✓ | ✗ (DOM 없음) | — |
| `[💾 Save Metadata]` | ✓ | ✗ | — |
| `[🚀 Activate]` | ✓ | ✗ | — |
| `[🗑 Delete]` | ✓ | ✗ | — |
| `[↩ Revert]` | ✓ | ✗ | — |

### 9.2 라우터 가드 (GER-03)

```typescript
// router/guards.ts
router.beforeEach((to, from, next) => {
  if (to.meta.requiredPermission === 'GraphicEditor:Read') {
    const auth = useAuthStore();
    if (!auth.hasPermission('GraphicEditor', 'Read')) {
      return next({ path: '/lobby/unauthorized' });
    }
  }
  next();
});
```

CCR-017 BitFlag RBAC: `auth.hasPermission(resource, action)` 는 권한 비트마스크 AND 연산으로 체크.

### 9.3 UI gate — 버튼 조건부 렌더링 (GER-01)

```vue
<q-btn
  v-if="auth.hasPermission('GraphicEditor', 'Write')"
  label="Upload .gfskin"
  icon="upload"
  color="primary"
  @click="openUploadDialog"
/>
```

Operator 세션에서는 `v-if` 가 false → DOM 자체가 생성되지 않는다. 단순 `:disable` 이 아닌 이유: 악의적 DevTools 로 disabled 해제를 시도해도 버튼 자체가 없어야 한다 (BS-08-04 §2.2).

### 9.4 Operator 읽기 전용 배너 (GER-02)

```vue
<q-banner
  v-if="isOperator"
  rounded
  class="bg-info text-white q-mb-md"
  icon="visibility"
>
  읽기 전용 모드 — Graphic Editor 편집은 Admin 권한이 필요합니다.
</q-banner>
```

모든 메타데이터 `TextField` / `DropdownButton` / `q-color` 에 `:readonly="isOperator"` 또는 `:disable="isOperator"` 부여.

rive-js 프리뷰 Play/Pause/Reset 버튼도 Operator 에게는 비활성화 (비인터랙티브 캔버스만 렌더).

### 9.5 Viewer redirect (GER-03)

Viewer 가 URL bar 로 `/lobby/graphic-editor` 직접 접근 → §9.2 가드가 감지 → `/lobby/unauthorized` 로 redirect. 동시에 `$q.notify({ type: 'negative', message: '접근 권한이 없습니다.' })`.

### 9.6 API 서버측 재검증 (GER-04)

UI gate 는 악의적 클라이언트가 우회 가능하므로, 서버(Team 2)가 모든 mutation 엔드포인트에서 JWT role 을 재검증한다. 403 수신 시 클라이언트는 토스트만 표시 (라우팅/로그아웃 없음, BS-08-04 §4):

```typescript
// axios interceptor
if (error.response?.status === 403 && error.response?.data?.error === 'AUTH_ROLE_DENIED') {
  $q.notify({
    type: 'negative',
    message: 'Admin 권한이 필요한 작업입니다. Admin에게 문의하세요.',
    timeout: 4000
  });
}
```

---

## 10. 에러 / 로딩 / 빈 상태

UI-00 §12 상태 패턴을 GE 허브에 적용한다. 상태별 컴포넌트는 다음과 같다.

### 10.1 초기 로딩 (전체 3-Zone)

```
┌───────────────────────────────────────────────┐
│ Header                                        │
├──────────────────┬────────────────────────────┤
│ q-skeleton       │ q-skeleton rect 640×480    │
│  type="text"     │                            │
│  (× 5)           │ q-skeleton text × 10       │
│                  │                            │
└──────────────────┴────────────────────────────┘
```

`useGeStore.status = 'loading'` 동안 표시. `GET /skins` 응답 수신 후 실제 리스트로 교체.

### 10.2 빈 상태 (스킨 0개)

UI-00 §12.3 `EmptyState` 컴포넌트 재사용:

```vue
<EmptyState
  icon="palette"
  title="아직 업로드된 스킨이 없습니다"
  description="Rive 공식 에디터로 .gfskin 파일을 만든 뒤 업로드하세요."
  :action="{ label: '📦 Upload .gfskin', handler: openUploadDialog }"
/>
```

Admin 에게만 action 버튼 표시. Operator/Viewer 는 메시지만 표시 (버튼 `v-if` 생략).

### 10.3 Upload 중 진행 (§6.3)

- `LinearProgressIndicator` 단계별 caption
- 실패 시 `q-banner role="alert"` 최상단 표시

### 10.4 Upload 실패 에러

BS-08-01 §2.7 `failed` 상태 UI:

```
┌─────────────────────────────────────────────┐
│ ⚠ 업로드 실패                               │
│                                             │
│ skin.json 검증 실패: colors.badge_check     │
│ 필드가 #hex 패턴을 만족하지 않습니다.       │
│                                             │
│ ▸ 상세 정보 보기 (기술 로그)                │
│                                             │
│             [재시도]  [취소]                │
└─────────────────────────────────────────────┘
```

- 상위 1줄: 사용자 친화 문구 (한글)
- 하위: `q-expansion-item` 으로 기술 상세 (stack trace, JSON path) 접기
- 재시도 → 같은 파일로 `uploadSkin` 재호출, 취소 → dialog close

### 10.5 Metadata Save 에러

| HTTP | 문구 |
|------|------|
| 412 | "다른 사용자가 먼저 변경했습니다. 새로고침할까요?" (q-dialog) |
| 422 | 필드 하단 inline 에러 + "저장 실패: 입력값을 확인하세요" 배너 |
| 403 | "Admin 권한이 필요합니다" 토스트 |
| 5xx | "서버 오류. 잠시 후 재시도하세요" 토스트 + [재시도] |

### 10.6 Activate 에러

§8.4 응답 처리 표 참조. 모든 에러는 `activationState = 'error'` 로 수렴하고, 버튼 라벨이 `⚠ Retry Activate` 로 변경.

### 10.7 rive-js Preview 로드 실패

```
┌─────────────────────────────────────────────┐
│     ⚠ Rive 파일을 로드할 수 없습니다.       │
│                                             │
│     [↻ 재시도]                              │
│                                             │
│     ▸ 상세 에러                             │
└─────────────────────────────────────────────┘
```

캔버스 영역을 `q-card bordered` 로 대체, 재시도 버튼 클릭 시 `createRive()` 재호출.

### 10.8 WS 연결 끊김

`useWsStore.status = 'disconnected' | 'reconnecting'` 동안 Zone 3 상단에 `q-banner` 표시:

```
🔌 실시간 업데이트 연결이 끊어졌습니다. 재연결 중...
```

재연결 성공 시 `useWsStore.replay(lastSeq)` 를 자동 호출해 누락 이벤트 복구.

### 10.9 접근성 공통

- 모든 에러 배너는 `role="alert" aria-live="assertive"`
- 로딩 스켈레톤에는 `aria-busy="true"` + 인접 텍스트 "로딩 중"
- 모든 인터랙티브 요소는 키보드 포커스 가능 (`tabindex`) + `focus-visible` 스타일 (UI-00 §10)
- 이미지 없는 빈 상태 아이콘은 `aria-hidden="true"` + 대체 텍스트는 `title` 로

---

## 11. 관련 CCR

| CCR | 상태 | 변경 대상 | 관련 섹션 |
|-----|------|----------|-----------|
| **CCR-011** ge-ownership-move | APPLIED | `BS-08-00~04`, `BS-00 §7.4` | 전체 (소유권·범위 정의) |
| **CCR-012** gfskin-format-unify | APPLIED | `DATA-07`, `BS-07-03` | §6 Upload 검증, §5 편집 매트릭스 |
| **CCR-013** ge-api-spec | APPLIED | `API-07` | §4 Flows, §5 PATCH, §8 Activate |
| **CCR-014** ge-req-id-rework | APPLIED | `BS-00 §7.4` | GEI-01~08 / GEM-01~25 / GEA-01~06 / GER-01~05 prefix 근거 |
| **CCR-015** skin-updated-ws | APPLIED | `API-05` | §8.5 WS broadcast, §8.6 Replay |
| **CCR-025** bs03-graphic-settings-tab | APPLIED | `BS-03-02-gfx` | §5 Metadata 와 Settings 탭 경계 (BS-03 은 비시각 설정만, 본 문서는 `.gfskin` 메타만) |

CCR 원문 경로 (읽기 전용 참조):

- `docs/05-plans/ccr-inbox/promoting/CCR-011-ge-ownership-move.md`
- `docs/05-plans/ccr-inbox/promoting/CCR-012-gfskin-format-unify.md`
- `docs/05-plans/ccr-inbox/promoting/CCR-013-ge-api-spec.md`
- `docs/05-plans/ccr-inbox/promoting/CCR-014-ge-req-id-rework.md`
- `docs/05-plans/ccr-inbox/promoting/CCR-015-skin-updated-ws.md`
- `docs/05-plans/ccr-inbox/promoting/CCR-025-bs03-graphic-settings-tab.md`

---

## 12. 연관 문서

| 문서 | 관계 |
|------|------|
| `team1-frontend/ui-design/UI-00-design-system.md` | Quasar 컴포넌트 매핑(§9), 반응형(§8), 상태 패턴(§12), 접근성(§10) |
| `team1-frontend/ui-design/UI-A1-architecture.md` | 라우터(§2.1), `useGeStore`(§3.2.4), axios Idempotency-Key(§4.3), WS seq 검증(§5) |
| `team1-frontend/ui-design/UI-01-lobby.md` | Lobby 사이드바에서 GE 메뉴 진입점 |
| `team1-frontend/ui-design/UI-03-settings.md` | 비시각 Settings(Game/Stats/Output)와 GE의 경계 (CCR-025) |
| `../specs/BS-08-graphic-editor/BS-08-00~04.md` | 행동 명세 SSOT (변경 금지, CCR 경유) |
| `contracts/api/API-07-graphic-editor.md` | 8 엔드포인트 계약 |
| `contracts/data/DATA-07-gfskin-schema.md` | `.gfskin` 포맷 + JSON Schema SSOT |
| `contracts/api/API-05-websocket-events.md` | `skin_updated` 이벤트 정의 |
