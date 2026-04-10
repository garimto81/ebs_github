# BO-03 Operations — 감사 로그 & 리포팅

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | BO-08 + BO-11 병합. 운영 정책/카탈로그만 유지, API 엔드포인트는 API-01로 이관 |

---

## 개요

BO의 운영 관련 정책 — 감사 로그 기록 대상/보존 정책, 리포트 카탈로그, 내보내기 형식을 정의한다.

> API 엔드포인트: API-01 Backend Endpoints §감사 로그, §리포트
> 데이터 모델: DATA-02 Entities §audit_logs

---

## Part 1: 감사 로그

## 1. 기록 대상 매트릭스

### 1.1 기록 대상

| 분류 | 이벤트 | 기록 내용 |
|------|--------|----------|
| **인증** | 로그인/로그아웃 | 사용자, IP, 역할, 시각 |
| **인증** | 로그인 실패 | 이메일, IP, 실패 사유, 시각 |
| **인증** | 2FA 활성화/비활성화 | 사용자, 시각 |
| **사용자** | 사용자 생성/수정/비활성화 | 대상 사용자, 변경 내용, 실행 Admin |
| **사용자** | 역할 변경 | 이전/이후 역할, 실행 Admin |
| **대회** | Series/Event/Flight 생성/수정/삭제 | 대상 엔티티, 변경 내용, 실행 Admin |
| **테이블** | 테이블 CRUD | 대상 테이블, 변경 내용, 실행 Admin |
| **테이블** | 상태 전환 | 이전/이후 상태, 실행 사용자 |
| **플레이어** | 플레이어 등록/제거 | 대상 플레이어, 테이블, 실행 Admin |
| **좌석** | 좌석 배치/변경/비우기 | 이전/이후 좌석, 플레이어, 실행 Admin |
| **RFID** | 리더 할당/해제 | 리더 ID, 테이블, 실행 Admin |
| **설정** | Config 변경 | 키, 이전/이후 값, 실행 Admin |
| **장애** | 장애 발생/복구 | 장애 유형, 시각, 영향 범위 |
| **CC** | CC 연결/해제 | table_id, operator, 시각 |

### 1.2 기록하지 않는 것

| 제외 대상 | 이유 |
|----------|------|
| 핸드 개별 액션 (Fold, Bet 등) | `hand_actions` 테이블에 별도 저장 |
| API 읽기 요청 (GET) | 볼륨 과다, 보안 가치 낮음 |
| WebSocket 하트비트 | 시스템 레벨 로그에 별도 기록 |

---

## 2. details JSON 구조

**테이블 상태 변경:**
```json
{
  "field": "status",
  "old_value": "SETUP",
  "new_value": "LIVE",
  "table_name": "Table 1"
}
```

**설정 변경:**
```json
{
  "field": "system.rfid_mode",
  "old_value": "mock",
  "new_value": "real"
}
```

---

## 3. 보존 정책

| 항목 | 값 | 설명 |
|------|:--:|------|
| 보존 기간 | 시리즈 종료 후 1년 | 감사 요구사항 충족 |
| 아카이빙 | 1년 경과 → 압축 아카이브 | 조회 불가, 필요 시 복원 |
| 삭제 | 아카이브 후 2년 | 영구 삭제 |
| 수정 금지 | append-only | 기존 로그 수정/삭제 API 없음 |

---

## 4. 유저 스토리

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| A-1 | Admin | 감사 로그 메뉴 진입 | 최근 로그 시간순 목록 표시 | 로그 0건: "기록된 감사 로그가 없습니다" |
| A-2 | Admin | 시간 범위 + 사용자 필터 | 필터 조건에 맞는 로그만 표시 | 결과 0건: "조건에 맞는 로그가 없습니다" |
| A-3 | Admin | 로그 항목 클릭 | 상세 (이전값/이후값, IP, 시각) 표시 | — |
| A-4 | Operator | 감사 로그 접근 시도 | 403 Forbidden | Admin 전용 |

---

## Part 2: 리포팅

## 5. 리포트 카탈로그

| 리포트 | 설명 | 데이터 소스 | 대상 |
|--------|------|-----------|:----:|
| **Event Summary** | 이벤트별 전체 요약 (핸드 수, 플레이어 수, 소요 시간) | `events`, `hands`, `hand_players` | Admin |
| **Table Activity** | 테이블별 활동 요약 (핸드 수, 평균 팟, 평균 소요 시간) | `tables`, `hands` | Admin |
| **Player Statistics** | 플레이어별 VPIP/PFR/AGR/P&L 종합 | `hand_players`, `hand_actions` | Admin |
| **Hand Distribution** | 핸드 유형별 분포 (게임 종류, 팟 크기, 승리 방식) | `hands`, `hand_players` | Admin |
| **RFID Health** | RFID 리더별 인식률, 에러 빈도, 가동 시간 | 실시간 로그 | Admin |
| **Operator Activity** | Operator별 핸드 처리 수, 평균 핸드 시간 | `hands`, `audit_logs` | Admin |

---

## 6. Dashboard 요약 데이터

| 지표 | 계산 | 갱신 주기 |
|------|------|----------|
| 오늘 총 핸드 수 | `hands` COUNT (today) | 실시간 |
| 활성 테이블 수 | `tables` COUNT (status=LIVE) | 실시간 |
| 활성 플레이어 수 | `table_seats` COUNT (status=OCCUPIED) | 실시간 |
| 평균 핸드 소요 시간 | `hands.duration_sec` AVG (today) | 5분 |
| 평균 팟 크기 | `hands.pot_total` AVG (today) | 5분 |
| RFID 에러 건수 | 에러 로그 COUNT (today) | 실시간 |

---

## 7. 내보내기

### 7.1 형식

| 형식 | 용도 | 최대 크기 |
|------|------|----------|
| **CSV** | 스프레드시트 분석 | 10MB (약 100,000행) |
| **JSON** | 프로그래밍 연동 | 10MB |

### 7.2 대상

| 데이터 | 포함 필드 |
|--------|----------|
| 핸드 목록 | hand_number, game_type, pot, winner, duration, timestamp |
| 플레이어 통계 | name, hands_played, vpip, pfr, agr, total_pnl |
| 테이블 활동 | table_name, hands_count, avg_pot, avg_duration, status |
| 감사 로그 | timestamp, user, action, entity, details |

---

## 8. 역할별 접근 매트릭스

| 역할 | Dashboard 조회 | 상세 리포트 | 내보내기 | 감사 로그 |
|:----:|:-------------:|:----------:|:--------:|:--------:|
| Admin | O | O | O | O |
| Operator | X | X | X | X |
| Viewer | O (읽기) | O (읽기) | X | X |

---

## 비활성 조건

- BO 서버 미실행: 감사 로그 기록/조회, 리포트 조회 불가
- 핸드 데이터 0건: 리포트 생성 불가 (빈 상태 안내)
- Operator: 감사 로그, 리포트 접근 불가
- DB 용량 부족: 경고 후 오래된 로그 강제 아카이빙

## 영향 받는 요소

| 영향 대상 | 관계 |
|----------|------|
| BO-01 Core | 인증/역할/대회/테이블 변경 기록 |
| BO-02 Game Engine | 핸드 데이터 = 리포트 주요 소스 |
| BS-02-lobby.md | Lobby 감사 로그 항목 정의 |
