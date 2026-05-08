---
title: NOTIFY team1 Round2 — user_sessions 다중 기기 · configs/preferences 이관
owner: team2
tier: internal
confluence-page-id: 3819274964
confluence-parent-id: 3811770578
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819274964/EBS+NOTIFY+team1+Round2+user_sessions+configs+preferences
---

# NOTIFY — team1 Round 2 Backend 영향 2건

**발신**: team1  
**수신**: team2  
**일자**: 2026-04-15  
**근거 PR**: #4

## 1. `user_sessions` 테이블 컬럼 2개 추가 + audit 이벤트 4종

### 배경

`Lobby/Session_Restore.md §다중 기기 동시 로그인 정책` 에서 "마지막 활동 기기 우선 + 2분 비활동 자동 로그아웃" 규칙 정의. Backend 구현 필요.

### 스키마 변경

```sql
ALTER TABLE user_sessions
  ADD COLUMN last_activity_at TIMESTAMP NOT NULL DEFAULT now(),
  ADD COLUMN device_id VARCHAR(64) NOT NULL;

CREATE INDEX idx_user_sessions_activity ON user_sessions (user_id, last_activity_at DESC);
```

### API 동작 변경

- 모든 인증 필요 엔드포인트: 매 요청마다 `last_activity_at = now()` 갱신 (또는 토큰 검증 미들웨어에서 일괄)
- `X-Device-Id` 헤더 필수화 (클라이언트가 UUID 생성)
- 2분 비활동 세션은 토큰 검증 시 `401 AUTH_SESSION_INACTIVE` 반환
- 세션 복원 API (`GET /auth/session`) 는 `last_activity_at` 이 가장 최근인 세션의 `last_table_id` 우선 반환

### audit_events 이벤트 4종

| event_type | 기록 시점 | payload |
|-----------|----------|---------|
| `session_started` | 로그인 성공 | device_id, ip, user_agent |
| `session_ended_inactive` | 2분 비활동 자동 만료 | last_activity_at, duration_sec |
| `session_ended_explicit` | 로그아웃 버튼 | — |
| `session_takeover` | 다른 기기에서 same last_table_id 진입 시도 | conflict_device_id |

## 2. `/configs/preferences/*` 엔드포인트 → Lobby/Operations 소유 이관

### 배경

Round 2 Phase C 에서 `Settings/Preferences.md` 를 `Lobby/Operations.md` 로 이전. Backend API 경로·DB 스키마는 변경 없으나 **의미적 소유자가 Lobby operations** 로 바뀜.

### Backend 영향

- API 경로 변경 없음 (`PUT /configs/preferences/{key}` 유지)
- DB 스키마 변경 없음 (`configs` 테이블 `category='preferences'` 유지)
- `Backend_HTTP.md §5.11 Configs` 문서에 "preferences category 는 Lobby/Operations.md 소유" 주석 추가

### 액션

- [ ] team2: `Backend_HTTP.md §5.11` 주석 추가
- [ ] team2: 향후 Preferences 관련 CCR 은 `Lobby/Operations.md` 를 참조

## 참조

- `../../2.1 Frontend/Lobby/Session_Restore.md §다중 기기 동시 로그인 정책`
- `../../2.1 Frontend/Lobby/Operations.md`
