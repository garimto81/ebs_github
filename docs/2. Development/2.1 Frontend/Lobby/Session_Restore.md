---
title: Session Restore
owner: team1
tier: internal
legacy-id: BS-02-01-session-restore
last-updated: 2026-04-15
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "BS-02-01-session-restore 복구 플로우 완결"
---
# Lobby — Session Restore (재진입 세션 복원)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-15 | v10 분할 | 구 `BS-02-01-auth-session.md` §유저 스토리 K. 세션 복원 을 본 파일로 분리 (Login 화면 아닌 Lobby 진입 후 복원 흐름이므로 Lobby/ 배치). |
| 2026-04-15 | 다중 기기 정책 | §다중 기기 동시 로그인 정책 신설 (마지막 활동 기기 우선·비활동 2분 자동 로그아웃). team1 발신, Round 2 Phase A. |

---

## 개요

정상/비정상 종료 후 재접속 시 이전 Command Center 상태 복원 흐름을 정의한다. 토큰 검증 가드 통과 후 실행된다.

> **관련**:
> - 토큰 검증 가드: `../Login/Error_Handling.md` §GAP-L-001
> - 세션 저장 데이터: `../Login/Session_Init.md` §세션 저장 데이터
> - Lobby 진입: `Overview.md`

---

## 유저 스토리 — K. 세션 복원

> 정상/비정상 종료 후 재접속 시 이전 상태 복원. (구 BS-02-00-overview.md 의 유저 스토리 A~K 시리즈 중 K. 세션 복원 부분.)

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| K-1 | 모든 역할 | 정상 로그아웃 후 재로그인하면 | 마지막 선택 (Series/Event/Table) 복원 다이얼로그 표시. Continue/Change Event/Change Series 옵션 | 마지막 선택 항목이 Completed 상태: 해당 항목 건너뛰고 상위 레벨로 이동 |
| K-2 | 모든 역할 | 비정상 종료(앱 크래시) 후 재접속하면 | `user_sessions` 테이블에서 마지막 상태 로드. K-1과 동일한 복원 다이얼로그 | `user_sessions` 레코드 없음: 첫 접속과 동일 (Series 선택부터) |
| K-3 | Operator | 세션 복원 시 할당 테이블이 변경됨 | 새 할당 테이블 목록으로 갱신. 이전 테이블이 할당 해제됨: "할당 해제된 테이블입니다" 안내 후 현재 할당 목록 표시 | — |
| K-4 | 모든 역할 | Continue 선택 시 이전 테이블이 삭제됨 | "테이블이 더 이상 존재하지 않습니다" 안내 후 Flight 목록으로 이동 | — |

---

## 복원 다이얼로그 옵션

| 옵션 | 동작 |
|------|------|
| **Continue** | 저장된 `last_table_id` Command Center로 바로 진입 |
| **Change Event** | 현재 Series 유지, Event 선택 화면으로 |
| **Change Series** | 전체 초기화, Series 선택 화면으로 |

---

## Fallback Ladder

| 시도 | 실패 시 다음 단계 |
|------|------------------|
| 1. `last_table_id` Command Center 진입 | 테이블 삭제/종료 → 2 |
| 2. `last_flight_id` Flight 내 Table 목록 | Flight 종료 → 3 |
| 3. `last_event_id` Event 내 Flight 목록 | Event 종료 → 4 |
| 4. `last_series_id` Series 내 Event 목록 | Series 종료 → 5 |
| 5. Series 선택 화면 (최초 접속과 동일) | — |

---

## 다중 기기 동시 로그인 정책 (2026-04-15)

같은 계정으로 다른 기기(PC 1, PC 2, 모바일 등) 에서 동시 접속 가능. 단 `last_table_id` 충돌 방지를 위한 규칙을 둔다.

### 정책 — "마지막 활동 기기 우선 + 2분 비활동 자동 로그아웃"

| 시나리오 | 처리 |
|---------|------|
| 기기 A 가 Table T1 진입, 기기 B 가 같은 계정으로 로그인 | B 로그인 허용. B 는 빈 Lobby 에서 시작 (A 의 `last_table_id` 무시) |
| A 가 활동 중일 때 B 가 Table T2 선택 | B 의 진입 허용. `user_sessions.last_table_id = T2` 갱신 (B 가 마지막 활동) |
| A 가 다음 페이지 클릭 시도 | A 의 세션 토큰이 여전히 유효하면 A 도 활동 가능. A 와 B 모두 자기 화면을 진행 가능 (서버는 둘 다 별개 세션으로 인지) |
| A 가 2분간 비활동 (아무 API 호출 없음) | A 의 세션 자동 로그아웃 (서버가 inactive timer 로 강제 만료). A 는 다음 액션 시도 시 401 → `/Login` |
| A 가 명시적 로그아웃 | A 의 세션만 종료. B 는 영향 없음 |

### 구현 규약

**Backend** (NOTIFY 필요):
- `user_sessions.last_activity_at` 컬럼 추가, API 호출마다 갱신
- 2분 비활동 자동 만료 cron (또는 lazy 검증: 매 토큰 검증 시 last_activity 확인)
- `last_table_id` 등 복원 필드는 **마지막 활동 세션** 의 값을 우선
- `device_id` 헤더 (UUID, 클라이언트 생성, localStorage 저장) 받아 세션 구분

**Frontend**:
- App 부팅 시 `device_id` 가 localStorage 에 없으면 `crypto.randomUUID()` 로 생성 후 저장
- 모든 API 요청에 `X-Device-Id` 헤더 자동 주입 (Axios interceptor)
- 401 응답 시 Error_Handling.md §토큰 매핑의 `AUTH_TOKEN_EXPIRED` 처리 흐름

### 사용자 안내

다중 기기 로그인 자체는 차단하지 않는다. 단 비활동 2분 후 자동 로그아웃됨을 Login 페이지 안내 문구에 명시:
- i18n 키: `login.multi_device_notice`
- 한글: "같은 계정으로 여러 기기 사용 가능. 2분 미사용 시 자동 로그아웃됩니다"

### Audit Log

다음 이벤트는 `audit_events` 에 기록:
- `session_started` (device_id, ip, user_agent)
- `session_ended_inactive` (last_activity_at, duration_sec)
- `session_ended_explicit` (logout 버튼)
- `session_takeover` (다른 기기에서 same `last_table_id` 진입 시도)

> 본 정책은 WSOP LIVE Staff App 의 다중 기기 패턴을 참고. EBS 는 Cashier · Floor Manager 가 PC + 태블릿 동시 사용하는 운영 환경을 가정하므로 강제 단일 세션 정책은 부적합.
