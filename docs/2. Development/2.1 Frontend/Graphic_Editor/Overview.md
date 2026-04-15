---
title: Overview
owner: team1
tier: internal
legacy-id: BS-08-00
last-updated: 2026-04-15
---

# BS-08-00 Graphic Editor — Overview

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | Team 1 Lobby GE 허브 역할/페르소나/use case 정의 (CCR-011) |

---

## 개요

Graphic Editor(이하 **GE**)는 EBS Overlay가 사용하는 `.gfskin` 스킨 아티팩트를 **업로드·검증·메타데이터 편집·Activate**하는 허브다. Team 1 Lobby의 `/lobby/graphic-editor` 탭으로 구현되며, Quasar (Vue 3) + rive-js (`@rive-app/canvas`) 기술 스택을 사용한다.

> **경계 결정 (CCR-011)**: GE는 Lobby 허브로 소유가 확정되었다. CC(Team 4 Flutter)는 `skin_updated` WebSocket 이벤트 수신 후 Overlay를 리렌더하는 **소비자**로 재정의된다. Transform/Animation/keyframe/color adjust 편집은 out-of-scope — 디자이너는 Rive 공식 에디터에서 `.riv`를 완성한 뒤 `.gfskin` ZIP으로 묶어 업로드한다.

---

## 1. 역할

| 역할 | 세부 |
|------|------|
| **Authoring 허브** | 디자이너가 `.gfskin` ZIP을 업로드·검증·프리뷰 |
| **Metadata 편집** | `skin.json`의 이름·버전·색상·폰트·해상도·애니메이션 duration만 수정 (GEM-01~25) |
| **Activate 지점** | `PUT /api/v1/skins/{id}/activate` 호출 + `skin_updated` WebSocket broadcast |
| **RBAC gate** | Admin 전용 편집, Operator 읽기 전용, Viewer 접근 차단 |

---

## 2. 페르소나

| 페르소나 | 역할 | 사용 경로 |
|----------|------|-----------|
| **Art Designer** | `.gfskin` 제작·업로드·메타데이터 조정 | 브라우저 (Quasar) |
| **Admin** | Activate 결정, RBAC gate 통과, 배포 책임 | 브라우저 (Quasar) |
| **Operator** | 리스트 조회, 프리뷰, 메타데이터 조회 (편집 불가) | 브라우저 (Quasar) |
| **Viewer** | GE 탭 접근 불가 | — |

---

## 3. Use Case 플로우

### 3.1 신규 스킨 배포

```
Designer: .riv 완성 (Rive 공식 에디터)
  ↓
Designer: .gfskin ZIP 묶기 (skin.json + skin.riv [+ cards/] [+ assets/])
  ↓
Admin: Lobby → Graphic Editor 탭 → Upload 버튼
  ↓
GE: ZIP 구조 검증 + JSON Schema 검증 (DATA-07) + Rive 파싱 확인
  ↓
GE: rive-js 프리뷰 렌더링
  ↓
Admin: Activate 버튼 클릭
  ↓
GE: GameState 확인 (X-Game-State 헤더), RUNNING이면 경고 다이얼로그
  ↓
GE → Backend: PUT /api/v1/skins/{id}/activate (If-Match ETag)
  ↓
Backend: active_skin_id 갱신 + skin_updated WS broadcast (seq 단조증가)
  ↓
모든 CC/Overlay 인스턴스: skin_updated 수신 → .gfskin 다운로드 → Overlay 리렌더
```

### 3.2 메타데이터 수정

```
Admin: 스킨 목록 → 스킨 선택 → Metadata 탭
  ↓
GE: GET /skins/{id}/metadata (If-Match ETag 수신)
  ↓
Admin: GEM-* 필드 편집 (색상/폰트/duration)
  ↓
GE: 로컬 JSON Schema 검증
  ↓
GE → Backend: PATCH /skins/{id}/metadata (JSON Merge Patch + If-Match)
  ↓
Backend: 검증 후 버전 증가, 새 ETag 반환
```

### 3.3 스킨 삭제

```
Admin: 스킨 목록 → 비활성 스킨 선택 → Delete
  ↓
GE → Backend: DELETE /skins/{id} (If-Match)
  ↓
Backend: active skin은 삭제 차단 (409 Conflict)
```

---

## 4. 3-Zone UI 레이아웃

GE 탭은 3개 Zone으로 구성된다 (상세 UI는 `team1-frontend/ui-design/UI-08-graphic-editor.md`).

| Zone | 내용 |
|------|------|
| **Left Zone** (List) | 업로드된 스킨 목록 (페이지네이션, 활성 표시) |
| **Center Zone** (Preview + Edit) | Rive 프리뷰 canvas + 메타데이터 편집 폼 |
| **Right Zone** (Actions) | Upload · Activate · Delete 버튼 + RBAC gate 상태 |

---

## 5. 8모드 참고 자산 (reference-only)

Team 4 원안의 "8모드(Board/Player/Dealer/House/Logo/Ticker/SSD/Action Clock) 99개 컨트롤 편집"은 YAGNI 및 Rive 공식 에디터 중복 사유로 **채택되지 않았다**. 그 정의는 `team4-cc/ui-design/reference/skin-editor/`에 보존되어 참고 자산으로만 유지된다.

디자이너 관점에서 편집 도구 책임:

| 도구 | 담당 |
|------|------|
| **Rive 공식 에디터** | Artboard, keyframe, transform, animation, color adjust, 8모드 전체 시각 |
| **EBS Graphic Editor (본 문서)** | `.gfskin` 업로드, JSON 메타데이터(이름/색상/폰트/duration), Activate, RBAC |

---

## 6. 연관 문서

| 문서 | 역할 |
|------|------|
| `BS-08-01-import-flow.md` | `.gfskin` 업로드 FSM |
| `BS-08-02-metadata-editing.md` | PATCH API + 편집 가능 필드 매트릭스 |
| `BS-08-03-activate-broadcast.md` | 멀티 CC 동기화 FSM |
| `BS-08-04-rbac-guards.md` | Admin/Operator/Viewer 행동 매트릭스 |
| `contracts/data/DATA-07-gfskin-schema.md` | `.gfskin` ZIP 포맷 + JSON Schema |
| `contracts/api/API-07-graphic-editor.md` | 8 엔드포인트 |
| `contracts/specs/BS-07-overlay/BS-07-03-skin-loading.md` | Overlay 로드 FSM |
| `contracts/api/API-05-websocket-events.md` | `skin_updated` 이벤트 (CCR-015, CCR-015 seq) |

---

## 7. 요구사항 매핑

본 문서가 커버하는 요구사항 prefix는 `BS-00 §7.4` 정의. 상세는 아래 파일 분할:

| Prefix | 문서 |
|--------|------|
| **GEI-01 ~ 08** | `BS-08-01-import-flow.md` |
| **GEM-01 ~ 25** | `BS-08-02-metadata-editing.md` |
| **GEA-01 ~ 06** | `BS-08-03-activate-broadcast.md` |
| **GER-01 ~ 05** | `BS-08-04-rbac-guards.md` |

---

## 8. Rive 호환성 (rive-js 프리뷰 구현 가이드)

> 2026-04-15 추가 (team1 발신). GE 의 프리뷰 canvas 및 메타데이터 cross-validation 구현에 필요한 버전·스키마·코드 예제를 고정한다.

### 8.1 지원 `@rive-app/canvas` 버전 범위

| 라이브러리 | 버전 | 채택 이유 |
|-----------|------|----------|
| `@rive-app/canvas` | **2.21.x** (허용 범위 `^2.21.0 <3`) | 2.x 는 runtime 3 호환. 3.x 는 breaking (API 변경) — 채택 보류 |
| 내부 `rive-wasm` | 2.21.x 에 번들 | 별도 설치 불요 |
| Rive 파일 포맷 runtime | `runtime >= 7` 만 허용 | 구버전 파일은 파싱 실패 유도 (`AUTH_INVALID_RIVE` 유사 에러) |

**Breaking 업그레이드 정책**: 3.x 검토는 별도 스토리. 업그레이드 전 본 문서 §8 과 `../Engineering.md §5.4` 의 `skin_updated` 처리, team3 Overlay 렌더러 간 통합 테스트 필수.

### 8.2 `skin.json` 필수 필드 cross-validation

> **SSOT**: `skin.json` 공식 스키마의 정답은 `../../2.2 Backend/APIs/Graphic_Editor_API.md §4.1` (team2 소유). 본 섹션은 그 스키마를 **클라이언트 fast-fail** 검증용으로 요약한 것이며, 필드 추가/변경 시 반드시 Backend SSOT 를 먼저 갱신한다.

`.gfskin` ZIP 의 `skin.json` 을 클라이언트에서도 검증한다. Backend 검증과 중복 허용 (fast-fail 목적).

| 필드 | 타입 | 제약 | 검증 위치 |
|------|------|------|----------|
| `schema_version` | int | `== 1` | 클라이언트 + 서버 |
| `skin_name` | string | 1~100자, `^[\w가-힣\-\s]+$` | 클라이언트 + 서버 |
| `resolution.width` | int | enum `{1920, 1080, 3840}` | 클라이언트 + 서버 |
| `resolution.height` | int | enum `{1080, 1920, 2160}` | 클라이언트 + 서버 |
| `resolution.width × height 조합` | — | 허용: 1920×1080, 1080×1920, 3840×2160 | **클라이언트 cross-check** |
| `layout_type` | string | enum `"horizontal" \| "vertical" \| "both"` | 클라이언트 + 서버 |
| `rive_runtime_version` | int | `>= 7` (현행 클라이언트 `@rive-app/canvas` 2.21.x 는 `7` 만 허용) | 클라이언트 + 서버 |
| `state_machines[]` | array | 각 항목 `{name, inputs: [...]}` | 클라이언트 |
| `state_machines[].inputs[].type` | string | enum `"boolean" \| "number" \| "trigger"` | 클라이언트 |

클라이언트 cross-check 예 (ajv 스키마와 별도 코드로):

```ts
function validateSkinJson(skin: SkinJson): ValidationError[] {
  const errors: ValidationError[] = []
  const { width, height } = skin.resolution
  const combos = [[1920,1080], [1080,1920], [3840,2160]]
  if (!combos.some(([w,h]) => w===width && h===height)) {
    errors.push({ field: 'resolution', code: 'INVALID_COMBO',
                  message: `${width}x${height} 는 지원 해상도 조합이 아닙니다` })
  }
  if (skin.layout_type === 'horizontal' && width < height) {
    errors.push({ field: 'layout_type', code: 'MISMATCH',
                  message: 'horizontal 레이아웃은 width > height 여야 합니다' })
  }
  // vertical 동일 체크...
  return errors
}
```

### 8.3 Rive state machine input 주입 (프리뷰 조작)

메타데이터 편집 화면의 프리뷰 canvas 에서 상태 전환·숫자 입력·트리거를 사용자가 직접 조작할 수 있어야 한다.

```ts
import { Rive, StateMachineInput } from '@rive-app/canvas'

const rive = new Rive({
  src: skinBlobUrl,            // ZIP 에서 추출한 .riv blob URL
  canvas: canvasRef.value,
  autoplay: true,
  stateMachines: ['MainSM'],   // skin.json.state_machines[0].name
  onLoad: () => {
    // 입력 핸들 가져오기
    const inputs = rive.stateMachineInputs('MainSM')
    const boolHandFeatured = inputs.find(i => i.name === 'handFeatured') as StateMachineInput
    const numSeatCount = inputs.find(i => i.name === 'seatCount') as StateMachineInput
    const trigRevealCards = inputs.find(i => i.name === 'revealCards') as StateMachineInput

    // UI 에서 주입
    toggleBtn.addEventListener('click', () => { boolHandFeatured.value = !boolHandFeatured.value })
    numberInput.addEventListener('input', (e) => { numSeatCount.value = Number(e.target.value) })
    actionBtn.addEventListener('click', () => { trigRevealCards.fire() })
  },
})
```

| 입력 타입 | 주입 방법 | UI |
|----------|----------|-----|
| `boolean` | `input.value = true/false` | Quasar `QToggle` |
| `number` | `input.value = N` | `QInput type="number"` 또는 `QSlider` |
| `trigger` | `input.fire()` | `QBtn` |

입력 목록은 `skin.json.state_machines[].inputs` 와 자동 대조하여 UI 를 동적 생성 (하드코딩 금지). 누락된 input 은 "스킨 정의와 불일치" 경고로 표시.

### 8.4 프리뷰 해상도 전환

| 설정 | 처리 |
|------|------|
| skin.layout_type == 'horizontal' | 프리뷰 canvas 16:9 고정, `width:100%` |
| skin.layout_type == 'vertical' | 프리뷰 canvas 9:16 고정, 높이 600px 기준 |
| skin.layout_type == 'both' | 드롭다운 토글 "Horizontal / Vertical" 제공, 선택 시 `rive.resizeDrawingSurfaceToCanvas()` 호출 |

### 8.5 리소스 정리

Rive 인스턴스는 메모리를 크게 점유한다. 컴포넌트 언마운트 시 반드시 cleanup:

```ts
onBeforeUnmount(() => {
  rive?.cleanup()
  rive = null
  // Blob URL 도 해제
  if (skinBlobUrl) URL.revokeObjectURL(skinBlobUrl)
})
```

메모리 누수 체크: Import 후 프리뷰 5회 반복 후 Chrome DevTools Memory 탭에서 Rive 관련 detached DOM 이 없어야 함 (QA 체크리스트).

> `skin.json` 스키마의 SSOT 는 `../../2.2 Backend/Database/Schema.md` (또는 `../../2.5 Shared/Skin_Schema.md` 신설 시 그쪽). 본 §8 은 그 스키마를 프리뷰 클라이언트에 적용하는 방법만 다룬다. 필드 추가/변경 시 Backend SSOT 선행 후 본 문서 §8.2 동기화.
