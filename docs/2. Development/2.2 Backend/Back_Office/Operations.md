---
title: Operations
owner: team2
tier: internal
legacy-id: BO-03
last-updated: 2026-05-08
confluence-page-id: 3818848758
confluence-parent-id: 3811770578
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818848758/EBS+Operations+0578
---

# BO-03 Operations — 감사 보존 정책 & 리포팅

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | BO-08 + BO-11 병합. 운영 정책/카탈로그만 유지, API 엔드포인트는 API-01로 이관 |
| 2026-04-10 | 감사 및 복구 보강 | audit_events 이벤트 스토어 관점 추가, §4 손실 데이터 복구 절차 신설 |
| 2026-04-10 | CCR-001/003/010 반영 | contracts 반영 완료 |
| 2026-04-14 | 중복 정리 | §1 감사 매트릭스→IMPL-07 §4.2 이관, §2 details JSON→IMPL-07 §2 흡수, §4.1-4.4 DR 시나리오→IMPL-10 §7.3 이관, §9 RBAC→API-06 §5 정본. BO-03은 보존 정책·복구 책임·유저 스토리·리포팅 정책만 유지 |
| 2026-05-08 | S7 정합성 감사 — Foundation v4.5 cascade | §2.1.E "중앙 서버 SPOF DR" 시나리오의 Foundation 옛 §8.5 표기를 Ch.6 Scene 4 (복수 테이블 운영) 로 정정. |

---

## 개요

BO 운영 정책 중 **다른 SSOT에 자연 위치가 없는 항목**만 정의:
- 감사 로그 보존·아카이빙 정책
- DR 시나리오의 책임 매트릭스 / 훈련 일정 / 운영자 유저 스토리
- 리포트 카탈로그 / Dashboard 메트릭 / 내보내기 형식

> **위임된 정본**:
> - 감사 기록 대상 14-카테고리 매트릭스 → **IMPL-07 §4.2**
> - 감사 로그 details JSON 구조 → **IMPL-07 §2**
> - 3-way 분리 (audit_logs/audit_events/hand_actions) → **IMPL-07 §4.1**
> - DR 시나리오 A-D 절차 → **IMPL-10 §7.3**
> - 역할별 접근 매트릭스 (RBAC) → **contracts/api/API-06 §5**
> - REST 엔드포인트 → **contracts/api/API-01 §감사 로그, §리포트**

---

## 1. 감사 로그 보존 정책

| 항목 | 값 | 설명 |
|------|:--:|------|
| 보존 기간 | 시리즈 종료 후 1년 | 감사 요구사항 충족 |
| 아카이빙 | 1년 경과 → 압축 아카이브 | 조회 불가, 필요 시 복원 |
| 삭제 | 아카이브 후 2년 | 영구 삭제 |
| 수정 금지 | append-only | 기존 로그 수정/삭제 API 없음 |

> `audit_events` 보존은 IMPL-07 §4.1 (1년, append-only) 참조. `audit_logs` 와 동일 정책.

---

## 2. DR 운영 정책

DR 시나리오 A-D의 **절차/페이징 규칙/Edge case**는 IMPL-10 §7.3 정본. 본 절은 운영 책임과 훈련만 정의.

### 2.1 복구 책임 매트릭스

| 시나리오 | 자동 복구 | 운영자 개입 | 개발팀 개입 |
|----------|:--------:|:----------:|:----------:|
| A: CC 크래시 | O (자동 replay + `/tables/{id}/state/snapshot` baseline 재로드, API-01 §5.18.7) | — | — |
| B: WSOP 동기화 분기 | O (부분) | 확인 필요 | 분기 대량 시 |
| C: Redis 손실 | O (degraded) | 모니터 | — |
| D: Saga 보상 실패 | X | **필수** | 로그 분석 |
| **E: 중앙 서버 SPOF** (2026-04-22 신설) | X | **필수** — 테이블 PC 들 로컬 fallback 진입 | 중앙 서버 재기동 |

### 2.1.E 중앙 서버 SPOF DR 시나리오 (Foundation Ch.6 Scene 4, 2026-04-22 신설)

Foundation Ch.6 Scene 4 "복수 테이블 운영" 의 N PC + 중앙 서버 배포 모델에서 중앙 서버(BO+DB) 다운 시 대응. 단일 PC 배포에는 무관.

| 단계 | 조건 | 조치 | 데이터 영향 |
|:----:|------|------|-------------|
| E-1 LAN 단절 감지 | WS disconnect 지속 > 30초 | 각 PC 의 Desktop App 은 **로컬 buffer 모드** 진입. CC 입력은 버퍼링, Overlay 는 마지막 state 유지 (API-05 §6.4 재연결 프로토콜 정합) | 쓰기 지연 (중앙 서버 복구 후 flush) |
| E-2 중앙 서버 다운 확인 | ICMP / health check 실패 | 운영자 판단 후: (a) 중앙 서버 재기동, (b) backup 서버로 DNS/IP 전환 (사전 준비 시), (c) 즉시 방송 일시 중단 | 방송 중단 vs 재기동 시간 trade-off |
| E-3 중앙 서버 복구 | WS 재연결 + snapshot 재로드 성공 | 각 PC: (1) `GET /tables/{id}/state/snapshot` 호출하여 baseline 재동기화, (2) 로컬 buffer 의 `CardDetected` / `ActionPerformed` 를 `Idempotency-Key` 와 함께 flush | `audit_events.seq` 단조 증가 보장. 중복 방지는 idempotency_keys 테이블 |
| E-4 장기 다운 (>15 min) | 운영자 판단 | DR 절차 (pg_dump restore + 로컬 SQLite fallback seed) | 해당 시간 구간은 `sync_conflicts` 에 기록 |

**fallback 세부**: `docs/4. Operations/Network_Deployment.md` 와 `Back_Office/Sync_Protocol.md §2 오프라인 대응` 참조. 본 §2.1.E 는 운영 책임 매트릭스만 명시.

**drill 요구사항**: E 시나리오 dry-run 은 **N PC 배포 전 필수**. 단일 PC 배포 팀은 skip.

### 2.2 DR 훈련 일정

출시 전 시나리오 A~D (+ N PC 배포 시 E) 드라이런 훈련 완료를 **배포 진입 게이트**로 설정 (IMPL-10 §10 항목 #13).

### 2.3 운영자 유저 스토리

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| A-1 | Admin | 감사 로그 메뉴 진입 | 최근 로그 시간순 목록 표시 | 로그 0건: "기록된 감사 로그가 없습니다" |
| A-2 | Admin | 시간 범위 + 사용자 필터 | 필터 조건에 맞는 로그만 표시 | 결과 0건: "조건에 맞는 로그가 없습니다" |
| A-3 | Admin | 로그 항목 클릭 | 상세 (이전값/이후값, IP, 시각, correlation_id, causation_id) 표시 | — |
| A-4 | Admin | correlation_id 링크 클릭 | `audit_logs` + `audit_events` 전체 범위에서 동일 correlation 이벤트 조회 | 분산 트레이싱 연동 |
| A-5 | Admin | 복구 대시보드 진입 (Scenario D) | 미해결 saga 목록 + `audit_cursor` 기반 단계별 상태 | 없으면 "정상" |
| A-6 | Admin | `audit_events` 특정 `seq` 범위 조회 | 단계별 이벤트 + inverse_payload 표시 | replay 및 감사 용 |
| A-7 | Operator | 감사 로그 접근 시도 | 403 Forbidden | Admin 전용 |

---

## 3. 리포팅

### 3.1 리포트 카탈로그

| 리포트 | 설명 | 데이터 소스 | 대상 |
|--------|------|-----------|:----:|
| **Event Summary** | 이벤트별 전체 요약 (핸드 수, 플레이어 수, 소요 시간) | `events`, `hands`, `hand_players` | Admin |
| **Table Activity** | 테이블별 활동 요약 (핸드 수, 평균 팟, 평균 소요 시간) | `tables`, `hands` | Admin |
| **Player Statistics** | 플레이어별 VPIP/PFR/AGR/P&L 종합 | `hand_players`, `hand_actions` | Admin |
| **Hand Distribution** | 핸드 유형별 분포 (게임 종류, 팟 크기, 승리 방식) | `hands`, `hand_players` | Admin |
| **RFID Health** | RFID 리더별 인식률, 에러 빈도, 가동 시간 | 실시간 로그 | Admin |
| **Operator Activity** | Operator별 핸드 처리 수, 평균 핸드 시간 | `hands`, `audit_logs` | Admin |

### 3.2 Dashboard 요약 데이터

| 지표 | 계산 | 갱신 주기 |
|------|------|----------|
| 오늘 총 핸드 수 | `hands` COUNT (today) | 실시간 |
| 활성 테이블 수 | `tables` COUNT (status=LIVE) | 실시간 |
| 활성 플레이어 수 | `table_seats` COUNT (status=OCCUPIED) | 실시간 |
| 평균 핸드 소요 시간 | `hands.duration_sec` AVG (today) | 5분 |
| 평균 팟 크기 | `hands.pot_total` AVG (today) | 5분 |
| RFID 에러 건수 | 에러 로그 COUNT (today) | 실시간 |

### 3.3 내보내기 형식

| 형식 | 용도 | 최대 크기 |
|------|------|----------|
| **CSV** | 스프레드시트 분석 | 10MB (약 100,000행) |
| **JSON** | 프로그래밍 연동 | 10MB |

**대상 데이터**:

| 데이터 | 포함 필드 |
|--------|----------|
| 핸드 목록 | hand_number, game_type, pot, winner, duration, timestamp |
| 플레이어 통계 | name, hands_played, vpip, pfr, agr, total_pnl |
| 테이블 활동 | table_name, hands_count, avg_pot, avg_duration, status |
| 감사 로그 | timestamp, user, action, entity, details |

> 역할별 접근 권한은 contracts/api/API-06 §5 RBAC 매트릭스 참조 (Admin: 전체, Operator: 없음, Viewer: 읽기 전용).

---

## 비활성 조건

- BO 서버 미실행: 감사 로그 기록/조회, 리포트 조회 불가
- 핸드 데이터 0건: 리포트 생성 불가 (빈 상태 안내)
- DB 용량 부족: 경고 후 오래된 로그 강제 아카이빙

## 영향 받는 요소

| 영향 대상 | 관계 |
|----------|------|
| PRD-EBS_BackOffice §3 | 인증/역할/대회/테이블 변경 기록 (기능 범위 SSOT) |
| IMPL-07 §4 | 감사 기록 대상 매트릭스 + details JSON SSOT |
| IMPL-10 §7.3 | DR 시나리오 절차 SSOT |
| API-06 §5 | RBAC 접근 매트릭스 SSOT |
| BS-02-lobby.md | Lobby 감사 로그 항목 정의 |
