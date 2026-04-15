---
title: Session Restore
owner: team1
tier: internal
legacy-id: BS-02-01-session-restore
last-updated: 2026-04-15
---

# Lobby — Session Restore (재진입 세션 복원)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-15 | v10 분할 | 구 `BS-02-01-auth-session.md` §유저 스토리 K. 세션 복원 을 본 파일로 분리 (Login 화면 아닌 Lobby 진입 후 복원 흐름이므로 Lobby/ 배치). |

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
