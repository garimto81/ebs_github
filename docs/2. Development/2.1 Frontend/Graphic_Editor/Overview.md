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
