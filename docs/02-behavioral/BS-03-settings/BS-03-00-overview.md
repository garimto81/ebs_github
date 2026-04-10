# BS-03-00 Overview — Settings 총괄

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Settings 4섹션 구조, 접근 권한, 변경 전파 정의 |
| 2026-04-09 | 6섹션 전면 재설계 | Console PRD v9.7 기반 Outputs/GFX/Display/Rules/Stats/Preferences |
| 2026-04-09 | 글로벌 Settings 명시 | Settings는 글로벌 단위 — 모든 CC 인스턴스에 동일 적용, 테이블별 Settings 없음 |

---

## 개요

Settings는 EBS **Lobby의 별도 하위 페이지**로, 오버레이 출력 파이프라인, 그래픽 배치, 수치 표시 형식, 게임 규칙, 통계/리더보드, 테이블 인증/진단/내보내기를 관리한다. **Settings는 글로벌 단위**로 모든 Command Center 인스턴스에 동일하게 적용된다 (테이블별 Settings 없음). Console PRD v9.7의 5탭(Outputs/GFX/Display/Rules/Stats) + Settings 다이얼로그(Preferences)를 행동 명세 6섹션으로 매핑한다.

> 참조: Console PRD v9.7 §2.7~§2.10

---

## 1. Settings 위치와 접근

### 1.1 아키텍처 내 위치

```
Lobby (웹)
  ├─ 4화면 네비게이션 (Series→Event+Flight→Table→Player)
  ├─ [Settings ⚙] ──→ Settings 페이지
  └─ [Enter CC] ──→ Command Center (Flutter 앱)
                        └─ [Settings ⚙] ──→ Settings 페이지 (동일)
```

- Settings는 Lobby 웹 내에서 렌더링되는 **페이지**
- CC에서 [Settings ⚙]를 누르면 Lobby 웹의 Settings가 열림

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

## 2. 6섹션 구조

### 2.1 Console PRD 매핑

| 섹션 | BS 문서 | Console PRD | 컨트롤 수 | 역할 |
|------|---------|-------------|:---------:|------|
| **Outputs** | BS-03-01 | §2.7 Outputs 탭 | 13 | 송출 파이프라인 (해상도, NDI/RTMP/SRT/DIRECT, Fill & Key) |
| **GFX** | BS-03-02 | §2.8 GFX 탭 | 14 | 그래픽 배치/카드/애니메이션 + SE 진입 |
| **Display** | BS-03-03 | §2.8b Display 탭 | 17 | 수치 표시 형식 (통화, 정밀도, BB 모드) |
| **Rules** | BS-03-04 | §2.9 Rules 탭 | 11 | 게임 규칙 + 플레이어 표시 |
| **Stats** | BS-03-05 | §2.9b Stats 탭 | 15 | Equity, Outs, Leaderboard, Score Strip |
| **Preferences** | BS-03-06 | §2.10 Settings 다이얼로그 | 9 | 테이블 인증, 진단, 내보내기 |

### 2.2 섹션 탭 UI

Settings 페이지 내부에 **6개 탭**이 수평 배치된다.

| 요소 | 동작 |
|------|------|
| 탭 바 | Outputs / GFX / Display / Rules / Stats / Preferences 6개 탭 |
| [Save] | 현재 탭의 변경사항을 BO DB에 저장 |
| [Cancel] | 변경사항 폐기, 마지막 저장 상태로 복원 |
| [Reset to Default] | 해당 섹션 전체를 기본값으로 초기화 (확인 다이얼로그 필수) |

> 참고: Preferences 탭은 즉시 적용 (Table Name/Password만 Update 버튼 커밋)

---

## 3. 설정 변경 전파

### 3.1 전파 흐름

```
Admin이 Settings 변경
  → BO REST API PUT /configs/{category}/{key}
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

---

## 4. BO 연동

### 4.1 API 엔드포인트

| 메서드 | 경로 | 설명 |
|:------:|------|------|
| GET | `/configs/{category}` | 섹션별 설정 조회 |
| PUT | `/configs/{category}/{key}` | 설정 변경 |
| POST | `/configs/reset` | 기본값 초기화 |
| GET | `/configs/presets` | 출력 프리셋 목록 |

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
