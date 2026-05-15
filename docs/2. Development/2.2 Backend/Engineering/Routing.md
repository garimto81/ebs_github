---
title: Routing
owner: team2
tier: internal
legacy-id: IMPL-04
last-updated: 2026-04-15
confluence-page-id: 3833593989
confluence-parent-id: 3811770578
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3833593989/Routing
---

# IMPL-04 Routing — CC go_router + Lobby 라우팅

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | CC go_router 경로, Lobby 라우팅, 가드, 딥링크, 세션 복원 |

---

## 개요

이 문서는 EBS의 **라우팅 설계**를 정의한다. Command Center(CC)는 go_router로 Flutter 앱 내 화면 전환을 관리하고, Lobby(웹)는 브라우저 라우팅(Next.js App Router 또는 React Router)을 사용한다.

> 참조: BS-00 §1 앱 아키텍처 용어, BS-00 §3.1 TableFSM, API-06 §5 RBAC 매트릭스

---

## 1. CC — go_router 라우트 트리

### 1.1 전체 라우트 맵

| 경로 | 화면 | 접근 조건 |
|------|------|----------|
| `/login` | 로그인 | 미인증 상태 |
| `/tables` | 테이블 선택 (할당된 테이블 목록) | 인증 완료 |
| `/table/:tableId` | 테이블 대기 (Setup/Paused/Closed) | 인증 + 테이블 할당 |
| `/table/:tableId/game` | 게임 진행 (HandFSM 기반) | 인증 + 테이블 LIVE |
| `/table/:tableId/deck` | 덱 등록 | 인증 + 테이블 SETUP |
| `/table/:tableId/rfid` | RFID 상태/진단 | 인증 + 테이블 할당 |

### 1.2 라우트 정의

```dart
final router = GoRouter(
  initialLocation: '/login',
  redirect: _globalRedirect,
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/tables',
      builder: (context, state) => const TableListPage(),
    ),
    GoRoute(
      path: '/table/:tableId',
      builder: (context, state) => TablePage(
        tableId: int.parse(state.pathParameters['tableId']!),
      ),
      routes: [
        GoRoute(
          path: 'game',
          builder: (context, state) => GamePage(
            tableId: int.parse(state.pathParameters['tableId']!),
          ),
        ),
        GoRoute(
          path: 'deck',
          builder: (context, state) => DeckRegistrationPage(
            tableId: int.parse(state.pathParameters['tableId']!),
          ),
        ),
        GoRoute(
          path: 'rfid',
          builder: (context, state) => RfidDiagnosticsPage(
            tableId: int.parse(state.pathParameters['tableId']!),
          ),
        ),
      ],
    ),
  ],
);
```

### 1.3 화면 전이 흐름

```
/login
  │ (인증 성공)
  ▼
/tables
  │ (테이블 선택)
  ▼
/table/:id ─────────────────────────────────
  │             │              │            │
  │ (Launch)    │ (덱 등록)    │ (RFID)     │
  ▼             ▼              ▼            │
/table/:id   /table/:id     /table/:id     │
  /game        /deck          /rfid         │
  │                                         │
  │ (핸드 종료 후 Pause/Close)              │
  └─────────────────────────────────────────┘
```

---

## 2. CC — 라우트 가드

### 2.1 가드 종류

| 가드 | 조건 | 리다이렉트 대상 | 우선순위 |
|------|------|---------------|:--------:|
| **인증 가드** | JWT Access Token 유효 여부 | `/login` | 1 |
| **RBAC 가드** | Admin 또는 Operator 역할 | `/login` (권한 부족 에러) | 2 |
| **테이블 할당 가드** | Operator의 할당 테이블 확인 | `/tables` | 3 |
| **테이블 상태 가드** | TableFSM 상태에 따른 화면 제한 | `/table/:id` | 4 |

### 2.2 글로벌 리다이렉트 로직

```
요청 경로 수신
  │
  ├── 토큰 없음? ──→ /login
  │
  ├── 토큰 만료? ──→ Refresh 시도
  │       ├── 성공 → 원래 경로 진행
  │       └── 실패 → /login
  │
  ├── /table/:id 접근 + Operator?
  │       └── table_ids에 :id 미포함? → /tables
  │
  ├── /table/:id/game 접근?
  │       └── TableFSM != LIVE? → /table/:id
  │
  └── 통과 → 원래 경로
```

### 2.3 테이블 상태별 허용 경로

| TableFSM | 허용 경로 | 차단 경로 |
|----------|----------|----------|
| **EMPTY** | `/table/:id` | `/game`, `/deck`, `/rfid` |
| **SETUP** | `/table/:id`, `/deck`, `/rfid` | `/game` |
| **LIVE** | `/table/:id`, `/game`, `/rfid` | `/deck` |
| **PAUSED** | `/table/:id`, `/rfid` | `/game`, `/deck` |
| **CLOSED** | `/table/:id` | `/game`, `/deck`, `/rfid` |

---

## 3. CC — 세션 복원

### 3.1 복원 흐름

```
앱 시작
  │
  ├── Secure Storage에서 Refresh Token 로드
  │       │
  │       ├── 없음 → /login
  │       │
  │       └── 있음 → POST /auth/refresh
  │               │
  │               ├── 성공 → 세션 데이터 로드
  │               │         │
  │               │         ├── last_table_id 존재?
  │               │         │     ├── YES → /table/:id (또는 /table/:id/game)
  │               │         │     └── NO → /tables
  │               │         │
  │               │         └── TableFSM 확인 후 적절한 하위 경로로 리다이렉트
  │               │
  │               └── 실패 → /login
```

### 3.2 저장 데이터

| 항목 | 저장 위치 | 복원 용도 |
|------|----------|----------|
| Refresh Token | flutter_secure_storage | 토큰 갱신 |
| last_table_id | BO user_sessions | 마지막 테이블 복원 |
| last_screen | BO user_sessions | 마지막 화면 복원 |

---

## 4. Lobby — 웹 라우팅

### 4.1 전체 라우트 맵

| 경로 | 화면 | 접근 조건 |
|------|------|----------|
| `/` | 로그인 | 미인증 |
| `/series` | Series 목록 | 인증 완료 |
| `/series/:id` | Series 상세 + Event 목록 | 인증 완료 |
| `/series/:sid/events/:eid` | Event 상세 + Flight 목록 | 인증 완료 |
| `/series/:sid/events/:eid/flights/:fid` | Flight 상세 + Table 목록 | 인증 완료 |
| `/series/:sid/events/:eid/flights/:fid/tables/:tid` | Table 상세 + Seat/Player | 인증 완료 |
| `/admin/users` | 사용자 관리 | Admin 전용 |
| `/admin/settings` | Settings (출력/오버레이/게임/통계) | Admin 전용 |
| `/admin/audit` | 감사 로그 | Admin 전용 |

### 4.2 라우트 계층

```
/ (로그인)
├── /series
│   └── /series/:id
│       └── /series/:sid/events/:eid
│           └── /series/:sid/events/:eid/flights/:fid
│               └── .../tables/:tid
│                   └── players (탭/패널)
├── /admin
│   ├── /admin/users
│   ├── /admin/settings
│   └── /admin/audit
```

### 4.3 Lobby 라우트 가드

| 가드 | 조건 | 리다이렉트 |
|------|------|----------|
| 인증 가드 | JWT 유효 여부 | `/` (로그인) |
| Admin 가드 | role === "admin" | `/series` (권한 부족 토스트) |
| Viewer 제한 | role === "viewer" | 쓰기 버튼 비활성화 (라우트 차단 아님) |

---

## 5. Lobby — 브레드크럼과 네비게이션

### 5.1 브레드크럼 패턴

```
Series > 2026 WSOP > Event #1: $10K NL Hold'em > Day 1A > Table 5
```

| 위치 | 클릭 동작 |
|------|----------|
| Series | `/series` 이동 |
| 2026 WSOP | `/series/1` 이동 |
| Event #1 | `/series/1/events/42` 이동 |
| Day 1A | `/series/1/events/42/flights/3` 이동 |
| Table 5 | 현재 페이지 (활성) |

### 5.2 세션 복원

| 항목 | 저장 위치 | 복원 시점 |
|------|----------|----------|
| 현재 URL | BO user_sessions.last_screen | 재로그인 시 |
| 선택된 Series/Event/Flight | SessionStorage | 탭 복원 |

---

## 6. 딥링크와 URL 공유

### 6.1 Lobby 딥링크

| URL 패턴 | 동작 |
|---------|------|
| `/series/1/events/42/flights/3/tables/5` | 해당 테이블 상세 페이지 직접 접근 |
| 미인증 상태로 접근 | 로그인 → 원래 URL로 리다이렉트 |

### 6.2 CC 딥링크

CC는 Flutter 데스크톱 앱이므로 URL 기반 딥링크를 지원하지 않는다. 대신 **커맨드라인 인자**로 초기 테이블을 지정할 수 있다.

```bash
ebs_cc.exe --table-id=5
```

| 인자 | 설명 | 기본값 |
|------|------|--------|
| `--table-id` | 시작 시 자동 선택할 테이블 ID | 없음 (테이블 선택 화면) |
| `--bo-url` | Back Office 서버 URL | `http://localhost:8000` |
| `--rfid-mode` | RFID 모드 (real/mock) | BO Config에서 로드 |
