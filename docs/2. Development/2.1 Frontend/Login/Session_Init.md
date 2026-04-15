---
title: Session Init
owner: team1
tier: internal
legacy-id: BS-02-01-session-init
last-updated: 2026-04-15
---

# Login — Session Init (로그인 성공 시 세션 생성)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-15 | v10 분할 | 구 `BS-02-01-auth-session.md` §세션 상태 보존 및 네비게이션 을 본 파일로 분리. |

---

## 개요

로그인 성공 직후 세션 저장 데이터 생성·breadcrumb 네비게이션 규칙을 정의한다.

> **관련**:
> - 로그인 폼: `Form.md`
> - 에러/가드: `Error_Handling.md`
> - 재접속 복원: `../Lobby/Session_Restore.md`
> - DB 스키마: `../../2.2 Backend/Database/Schema.md` (`user_sessions` 테이블)

---

## 세션 상태 보존 및 네비게이션

### 핵심 동작

Command Center에 진입하면 해당 테이블의 전체 경로(Series/Event/Table)가 **마지막 세션 상태**로 저장된다. 이후 로그인 시 저장된 Command Center로 바로 진입한다.

![세션 복원 흐름 — Login→복원 옵션→Command Center 자동 진입](../Lobby/visual/screenshots/ebs-flow-session-restore.png)

- Command Center가 호출된 적이 **있으면** → 다음 로그인 시 **바로 Command Center 호출** (마지막 테이블)
- Command Center가 호출된 적이 **없으면** → Lobby 3계층 탐색부터 시작 (최초 Setup)

> 참고: WSOP LIVE API 연동 전에는 Series/Event를 수동 생성한다. API 연동 후에는 자동 동기화되며, 수동 레코드와 API 레코드가 공존한다.

### Breadcrumb 네비게이션

Command Center 또는 Lobby 어디에서든 상단 breadcrumb로 **언제든 Setup 변경 가능**하다. 별도 모드 전환 없이 breadcrumb 클릭만으로 해당 레벨로 이동한다.

| 클릭 위치 | 이동 결과 | 세션 영향 |
|----------|----------|----------|
| Series 이름 | Series 선택 화면 | 하위 전부 초기화 |
| Event 이름 | Event 목록 화면 | Flight/Table 초기화 |
| Flight 이름 | Flight 선택 + Table 목록 | Table 초기화 |
| Table 이름 | Lobby Table 관리 화면 | Command Center 종료, Lobby 복귀 |

> 참고: breadcrumb에서 설정을 변경하고 새 테이블의 CC에 진입하면, 해당 경로가 새 세션 상태로 덮어쓴다.

### 세션 저장 데이터

| 필드 | 저장 시점 | 용도 |
|------|----------|------|
| `last_series_id` | Command Center 진입 시 | 로그인 시 Series 복원 |
| `last_event_id` | Command Center 진입 시 | 로그인 시 Event 복원 |
| `last_flight_id` | Command Center 진입 시 | 로그인 시 Flight 복원 |
| `last_table_id` | Command Center 진입 시 | 로그인 시 Table 복원 → Command Center 바로 진입 |

> 참고: 비정상 종료(앱 크래시, 네트워크 단절) 시에도 `user_sessions` 테이블에 마지막 상태가 영구 보존되어 있으므로 동일하게 복원된다. DB 스키마 상세는 `../../2.2 Backend/Database/Schema.md` `user_sessions` 테이블.

---

## 외부 참조 호환

본 파일의 H2/H3 슬러그는 분리 전 BS-02-00-overview.md 와 동일하게 보존되었다. 외부 API-06 (`../../2.2 Backend/APIs/Auth_and_Session.md`) 이 다음 anchor 를 참조한다:

| 외부 출처 | anchor | 본 파일 위치 |
|-----------|--------|--------------|
| API-06 L260 | `§세션 저장 데이터` | 본 파일 §세션 상태 보존 및 네비게이션 → 세션 저장 데이터 |
| API-06 L393 | `§화면 0: 로그인` | `Form.md` §화면 0: 로그인 |
