---
title: Overview
owner: team1
tier: internal
legacy-id: BS-03-00
last-updated: 2026-04-15
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "BS-03-00 Settings 총괄 완결. TBD 1건은 키보드 단축키 (블로커 아님)"
---
# BS-03-00 Overview — Settings 총괄

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Settings 4섹션 구조, 접근 권한, 변경 전파 정의 |
| 2026-04-09 | 6섹션 전면 재설계 | Console PRD v9.7 기반 Outputs/GFX/Display/Rules/Stats/Preferences |
| 2026-04-09 | 글로벌 Settings 명시 | Settings는 글로벌 단위 — 모든 CC 인스턴스에 동일 적용, 테이블별 Settings 없음 |
| 2026-04-15 | 적용 시점 구현 가이드 | §3.4 추가 — LOCK/CONFIRM/FREE 각 분류의 클라이언트 흐름(Mermaid), "다음 핸드 감지" 이벤트 매핑, 대기 중 변경 저장 store 필드 정의 (team1 발신, 기획 문서 충분성 보강). |
| 2026-04-15 | 5탭 구조로 축소 | Preferences 탭 제거 → `../Lobby/Operations.md` 로 이전 (테이블 운영 성격). Console_UI.md 폐기 반영으로 Console PRD 매핑 표 삭제. Outputs/GFX/Display/Rules/Stats 5탭만 유지 (team1 발신, Round 2). |

---

## 개요

Settings는 EBS **Lobby의 별도 하위 페이지**로, 오버레이 출력 파이프라인, 그래픽 배치, 수치 표시 형식, 게임 규칙, 통계/리더보드, 테이블 인증/진단/내보내기를 관리한다. **Settings는 글로벌 단위**로 모든 Command Center 인스턴스에 동일하게 적용된다 (테이블별 Settings 없음). Console PRD v9.7의 5탭(Outputs/GFX/Display/Rules/Stats) + Settings 다이얼로그(Preferences)를 행동 명세 6섹션으로 매핑한다.

> 참조: [`Legacy_Console_UI.md`](./Legacy_Console_UI.md) §2.7~§2.10 (구 Console PRD v9.7 역사 기록)

---

## 1. Settings 위치와 접근

### 1.1 아키텍처 내 위치

```
Lobby (웹)
  ├─ 3계층 네비게이션 (Series→Event→Table) + Player 독립 레이어
  ├─ [Settings ⚙] ──→ Settings 페이지
  └─ [Enter CC] ──→ Command Center (Flutter 앱)
                        └─ [Settings ⚙] ──→ Settings 페이지 (동일)
```

- Settings는 Lobby (Flutter Desktop 앱) 내에서 렌더링되는 **페이지**
- CC에서 [Settings ⚙]를 누르면 Lobby 창의 Settings 페이지가 열림 (OS window 전환)

### 1.2 접근 권한

| 역할 | Settings 접근 | 변경 권한 |
|------|:------------:|:---------:|
| **Admin** | O | 전체 |
| **Operator** | X | 없음 |
| **Viewer** | X | 없음 |

### 1.3 접근 방법

| 진입점 | 동작 | 비고 |
|--------|------|------|
| Lobby 헤더 [Settings ⚙] | Settings 페이지 열림 | 글로벌 설정 |
| CC 메뉴 [Settings ⚙] | Lobby Settings 페이지 열림 | 글로벌 설정 (테이블별 아님) |
| 키보드 단축키 (TBD) | Settings 페이지 열림 | Admin 전용 |

---

## 2. 5탭 구조

### 2.1 탭 구성

| 섹션 | 문서 | 컨트롤 수 | 역할 |
|------|------|:---------:|------|
| **Outputs** | `Outputs.md` | 13 | 송출 파이프라인 (해상도, NDI/RTMP/SRT/DIRECT, Fill & Key) |
| **Graphics** | `Graphics.md` | 12 | 그래픽 배치·카드·애니메이션 (Load Skin/GE 진입은 Lobby 헤더 독립 [Graphic Editor] 버튼으로 이동) |
| **Display** | `Display.md` | 17 | 수치 표시 형식 (통화, 정밀도, BB 모드) |
| **Rules** | `Rules.md` | 11 | 게임 규칙 + 플레이어 표시 |
| **Stats** | `Statistics.md` | 15 | Equity, Outs, Leaderboard, Score Strip |

> 구 Preferences 탭(테이블 인증·진단·내보내기) 은 **`../Lobby/Operations.md` 로 이전**. Settings 는 런타임 그래픽·송출 제어만 다룬다.

### 2.2 섹션 탭 UI

Settings 페이지 내부에 **5개 탭**이 수평 배치된다.

| 요소 | 동작 |
|------|------|
| 탭 바 | Outputs / Graphics / Display / Rules / Stats 5개 탭 |
| [Save] | 현재 탭의 변경사항을 BO DB 저장 |
| [Cancel] | 변경사항 폐기, 마지막 저장 상태로 복원 |
| [Reset to Default] | 해당 섹션 전체 기본값 초기화 (확인 다이얼로그 필수) |

---

## 3. 설정 변경 전파

### 3.1 전파 흐름

```
Admin이 Settings 변경
  → BO REST API PUT /Configs/{category}/{key}
    → BO DB configs 테이블 UPDATE
      → WebSocket ConfigChanged 이벤트 발행
        → 모든 CC가 수신
          → CC 적용 (시점은 아래 3.2 참조)
```

### 3.2 적용 시점

| CC 상태 | 적용 시점 | 이유 |
|--------|:--------:|------|
| 핸드 미진행 (IDLE) | **즉시** | 오버레이 표시만 변경 |
| 핸드 진행 중 | **다음 핸드 시작 시** | 현재 핸드 무결성 보호 |

### 3.3 LOCK/CONFIRM/FREE 연동

| 분류 | Settings 영향 | 예시 |
|:----:|-------------|------|
| **LOCK** | Settings에서 변경 불가 (비활성) | Game Type, Max Players |
| **CONFIRM** | 확인 다이얼로그 후 다음 핸드 적용 | Blinds, Output 설정 |
| **FREE** | 즉시 변경 및 적용 | GFX 레이아웃, Display 설정 |

### 3.4 적용 시점 플로우 (구현 가이드)

각 분류의 클라이언트 동작을 설계 수준으로 고정한다. 6탭 모두 이 규칙을 따른다.

```mermaid
flowchart TD
    Change[Admin이 설정 값 변경 + Save] --> Classify{LOCK/CONFIRM/FREE?}

    Classify -->|LOCK| Block[저장 버튼 비활성. 변경 시도 무시]
    Classify -->|FREE| PutFree[PUT /Configs/.../{key}]
    Classify -->|CONFIRM| ConfirmDlg[확인 다이얼로그 표시]

    PutFree --> BroadcastFree[BO가 ConfigChanged 발행]
    BroadcastFree --> ApplyFree[settingsStore.activeConfig 갱신 = 즉시 UI 반영]

    ConfirmDlg -->|취소| CancelFlow[변경 폐기]
    ConfirmDlg -->|확인| PutConfirm[PUT /Configs/.../{key}]
    PutConfirm --> CheckHand{현재 핸드 상태?}

    CheckHand -->|IDLE| ApplyNow[즉시 적용 = FREE 와 동일 경로]
    CheckHand -->|RUNNING| Pending[settingsStore.pendingConfigChanges 큐에 append]

    Pending --> WaitEvent[WebSocket HandEnded 또는 HandStarted 수신 대기]
    WaitEvent --> Drain[큐 전체 → settingsStore.activeConfig 일괄 적용]
    Drain --> Notify[토스트 '새 설정이 적용되었습니다']
```

### 3.5 클라이언트 구현 규약

**1) "다음 핸드 감지" 이벤트**

| 이벤트 | 용도 | 처리 |
|--------|------|------|
| `HandEnded` | 현재 핸드 종료 시각 | 큐 확인 → 대기 변경 있으면 다음 `HandStarted` 까지 블록 없이 대기 |
| `HandStarted` | 새 핸드 개시 시각 (핸드 번호 증가 직전) | **이 시점에 `pendingConfigChanges` 전체 drain + `activeConfig` 갱신** |
| `ConfigChanged` | 다른 Admin 이 변경 | 분류별로 위 플로우 재적용 (현재 Admin 이 대기 중인 변경과 key 충돌 시 서버값 우선, 로컬 큐에서 제거) |

> 구현 주의: 폴링 금지. 반드시 WebSocket 이벤트 기반. WebSocket 미연결 상태의 CONFIRM 변경은 저장은 되지만 적용이 지연되므로 Settings 하단에 "연결 복구 시 적용됨" 배너 표시.

**2) `settingsStore` (Pinia) 필수 필드**

```ts
interface SettingsStoreState {
  activeConfig: Record<string, unknown>       // 현재 실효 중인 설정 (ConfigChanged 반영)
  pendingConfigChanges: Array<{               // CONFIRM 분류 대기 큐
    key: string
    value: unknown
    category: 'Outputs'|'GFX'|'Display'|'Rules'|'Stats'|'Preferences'
    stagedAt: string                          // ISO 시각
    stagedBy: string                          // user_id
  }>
  gameState: 'IDLE' | 'RUNNING' | 'UNKNOWN'   // HandStarted/HandEnded 로 갱신
  handNumber: number                          // HandStarted 에서 갱신
  connectionLost: boolean                     // WebSocket 단절 배너 트리거
}
```

**3) 충돌 해결 규칙**

| 상황 | 결정 |
|------|------|
| 동일 key 를 A Admin 이 대기 큐에 담은 상태에서 B Admin 이 FREE 로 즉시 변경 | 서버의 `ConfigChanged` 가 도달하면 A 의 `pendingConfigChanges` 에서 해당 key 제거 + 토스트 "다른 관리자가 먼저 변경했습니다" |
| 동일 key 를 A 가 CONFIRM, B 가 CONFIRM 으로 큐에 넣음 | 서버 PUT 이 later-wins. 거부된 쪽은 로컬 큐에서 제거 + 토스트 "변경이 다른 저장에 의해 덮어써졌습니다" |
| WebSocket 단절 중 사용자가 CONFIRM 저장 | PUT 은 HTTP 로 성공 가능. 큐에는 담되 `connectionLost=true` 면 "연결 복구 시 적용됨" 배너. 재연결 시 서버가 최신 `ConfigChanged` 로 상태 복구하고 큐 정렬 |

**4) Reset to Default**

`POST /Configs/Reset` 은 카테고리 전체 초기화이므로 항상 **CONFIRM 분류로 간주**. 확인 다이얼로그 + 대기 큐 처리. 게임이 IDLE 이어도 시청자 경험 영향을 줄이기 위해 `HandStarted` 경계에서만 적용한다.

> 위 규약은 Pinia 설계와 Settings 6탭 전체의 "저장" 동작 구현의 SSOT. 각 탭 문서(Outputs.md 등) 는 자기 필드만 다루고 "언제 적용" 은 본 섹션을 참조한다.

---

## 4. BO 연동

### 4.1 API 엔드포인트

| 메서드 | 경로 | 설명 |
|:------:|------|------|
| GET | `/Configs/{category}` | 섹션별 설정 조회 |
| PUT | `/Configs/{category}/{key}` | 설정 변경 |
| POST | `/Configs/Reset` | 기본값 초기화 |
| GET | `/Configs/Presets` | 출력 프리셋 목록 |

### 4.2 WebSocket 이벤트

| 이벤트 | payload | 수신 대상 |
|--------|---------|----------|
| `ConfigChanged` | `{ key, value, category, changed_by }` | 모든 CC |

---

## 5. 유저 스토리

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| S-1 | Admin | Lobby에서 [Settings ⚙] 클릭 | Settings 페이지 열림, Outputs 탭 기본 표시 | Operator/Viewer: 버튼 미표시 |
| S-2 | Admin | CC에서 [Settings ⚙] 클릭 | 동일 Settings 페이지, 해당 테이블 컨텍스트 | CC 미실행: Lobby에서만 접근 |
| S-3 | Admin | Outputs 탭에서 해상도 변경 후 [Save] | `ConfigChanged` 이벤트 → CC 반영 | 핸드 진행 중: 다음 핸드부터 적용 |
| S-4 | Admin | [Reset to Default] 클릭 | 확인 다이얼로그 → 전체 기본값 복원 | "모든 설정이 초기화됩니다" |
| S-5 | Admin | [Cancel] 클릭 | 변경사항 폐기 | 저장되지 않은 변경 있으면 확인 다이얼로그 |

---

## 비활성 조건

| 조건 | 영향 |
|------|------|
| Admin이 아닌 역할 | Settings [⚙] 버튼 미표시 |
| BO 서버 미실행 | Settings 열림, 읽기 전용 (변경 불가) |
| 네트워크 단절 | Settings 열림, 로컬 캐시 표시, 변경 불가 |

## 영향 받는 요소

| 영향 대상 | 관계 |
|----------|------|
| BS-02 Lobby | Settings 진입점, LOCK/CONFIRM/FREE |
| BS-05 Command Center | ConfigChanged 수신, 설정 적용 |
| BS-07 Overlay | 스킨/레이아웃/통계 설정 반영 |
| BO-07 System Config | Settings의 BO 백엔드 |
