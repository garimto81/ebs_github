---
id: NOTIFY-team1-sandbox-toggle-ui
title: "team1 Lobby UI 협의 — Sandbox Toggle 배지 + ?include_sandbox"
status: PENDING
from: team2
to: team1
type: notify
created: 2026-04-21
---

# NOTIFY to team1 — Sandbox Toggle UI 협의

## 배경

team2 가 Sandbox Tournament Generator 기획 (`docs/2. Development/2.2 Backend/Engineering/Sandbox_Tournament_Generator.md` v0.2) 을 작성하고 B-068 구현 백로그를 생성함. 생성된 sandbox 시리즈/이벤트/플라이트/테이블이 Lobby 에 표시되기 위해 **team1 UI 협의** 가 필요.

## team1 에 요청하는 판단/작업

### 1. Sandbox 활성 배지 (Lobby 우상단)

**요구**: `GET /api/v1/sandbox/status` 폴링 결과가 `{enabled: true}` 이면 Lobby 우상단에 **"SANDBOX"** 배지 표시.

**제안 디자인**:
```
+------------------------------------------------+
| EBS Lobby      [2026-04-21]   [🟡 SANDBOX] [🔔] [User ▾] |
+------------------------------------------------+
```
- 색상: 주의 (amber/yellow 계열) — production 데이터 아님 경고
- 클릭 시 Settings > System 토글 화면으로 이동
- `{enabled: false}` 시 배지 숨김

### 2. Settings > System 탭 토글

**요구**: Lobby Settings > System 탭에 "Sandbox Mode" 토글 행 추가.

**제안 UI**:
```
+------------------------------------------------+
| Settings — System                              |
+------------------------------------------------+
|                                                |
|  Sandbox Mode                                  |
|  매일 3+ 무작위 토너먼트 자동 생성 (dev/staging 전용)    |
|                                     [●======] ON |
|                                                |
|  ▸ 현재: 12 series, 142 events 생성됨               |
|  ▸ 마지막 생성: 2026-04-21 00:00                   |
|  [ Generate Now ]  [ Reset All ]                |
+------------------------------------------------+
```

**동작**:
- ON → `POST /api/v1/sandbox/enable`
- OFF → `POST /api/v1/sandbox/disable`
- "Generate Now" → `POST /api/v1/sandbox/generate`
- "Reset All" → `POST /api/v1/sandbox/reset` (confirm 필요)

**RBAC**: 토글/버튼은 **Admin role 만 enabled**. operator/viewer 는 read-only 표시.

### 3. Lobby 리스트에서 sandbox 표시 구분

**요구**: Lobby 토너먼트 리스트 (Series/Event/Flight) 에 sandbox 항목 구분 표시.

**옵션 A (섹션 분리)**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PRODUCTION (12)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  2026 WSOP         Main Event         Day 2 running
  ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🟡 SANDBOX (3)                       [hide]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  2026-04-21 Sandbox Aria #1    $500 Kickoff    Day 1 running
```

**옵션 B (인라인 배지)**:
```
  [🟡SB] 2026-04-21 Sandbox Aria #1   $500 Kickoff   Day 1 running
  2026 WSOP                           Main Event     Day 2 running
```

team1 디자인 판단 필요 (team2 는 옵션 A 선호, 시각적 분리 강함).

### 4. API 쿼리 파라미터

**요구**: Lobby 가 sandbox 데이터를 받으려면 `GET /api/v1/{series,events,flights,tables}?include_sandbox=true` 호출 필요 (default 는 제외).

**제안 로직**:
```typescript
const includeSandbox = store.sandbox.enabled  // status 폴링 결과
const url = includeSandbox ? `/api/v1/series?include_sandbox=true` : `/api/v1/series`
```

토글 OFF 시 기존 series API 호출, ON 시 쿼리 파라미터 추가.

## team1 scope 침범 방지

이 NOTIFY 는 **협의 요청** 이다. team2 는 team1 코드 (`team1-frontend/`) 를 수정하지 않았다. team1 세션이 본 문서 확인 후:

1. Lobby UI 설계 문서 (`docs/2. Development/2.1 Frontend/Lobby/*.md`) 에 sandbox 토글/배지/리스트 표시 섹션 추가
2. `GET /api/v1/sandbox/status` 폴링 로직 Riverpod provider 신설
3. Settings > System 탭 UI 구현
4. Lobby 리스트 컴포넌트에 sandbox 구분 표시

## 수락 기준 (team1 측)

- [ ] Lobby 설계 문서에 §"Sandbox Mode UI" 섹션 추가 (옵션 A/B 결정)
- [ ] Settings > System 토글 행 디자인 결정 (mockup 포함)
- [ ] Admin RBAC 이외 접근 차단 UX 명시
- [ ] B-068 Phase F (API 격리 middleware) 완료 후 UI 구현 Backlog 작성

## 의사결정 필요 (team1)

| # | 질문 | team2 제안 |
|---|------|----------|
| 1 | Lobby sandbox 리스트 옵션 A vs B | A (섹션 분리) |
| 2 | 배지 색상 | Amber/Yellow (경고) |
| 3 | "Generate Now" 실행 중 UI 상태 | Disabled + spinner 표시 |
| 4 | sandbox OFF 전환 시 기존 데이터 어떻게 표시? | 기존 데이터 계속 표시, 새로 생성만 중단 (backend 동작과 일치) |

## 참조 문서

- Sandbox 기획 SSOT: `docs/2. Development/2.2 Backend/Engineering/Sandbox_Tournament_Generator.md` §1.1.1, §4.1
- B-068 구현 백로그: `docs/2. Development/2.2 Backend/Backlog/B-068-sandbox-tournament-generator.md`
- Backend_HTTP.md §1 (source enum 'sandbox' 추가 완료, 2026-04-21)

## Changelog

| 날짜 | 변경 |
|------|------|
| 2026-04-21 | 최초 작성 (team2 → team1 notify) |
