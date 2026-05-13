---
title: CR-team2-20260414-rate-limit-security
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team2-20260414-rate-limit-security
confluence-page-id: 3818816683
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818816683/EBS+CR-team2-20260414-rate-limit-security
---

# CCR-DRAFT: Rate Limiting & 보안 정책 정의 (OWASP + WSOP LIVE GGPass 준거)

- **제안팀**: team2
- **제안일**: 2026-04-14
- **영향팀**: [team1, team4]
- **변경 대상 파일**: contracts/specs/BS-01-auth/BS-01-auth.md, contracts/api/`Backend_HTTP.md` (legacy-id: API-01)
- **변경 유형**: add
- **변경 근거**: WSOP LIVE 엔드포인트별 Rate Limit 정책 문서 미발견(조사 결과). WSOP는 IP whitelist + 비밀번호 10회 실패 잠금만 명시. 정식 전체 개발에서 OWASP API Security Top 10 + WSOP LIVE 알려진 정책 조합으로 EBS rate limit 정책 명시화 필요. 현재 contracts에 rate limit 정의 전무 → 보안 공백.

## 변경 요약

1. BS-01-auth에 §Rate Limiting 섹션 신설 (카테고리별 정책 표)
2. 엔드포인트 카테고리 분류: 인증 / 쓰기 / 읽기 / WebSocket / Sync
3. 응답 헤더 표준 명시 (`X-RateLimit-*`, `Retry-After`)
4. Phase별 저장소: Phase 1 in-memory, Phase 2 Redis
5. IP whitelist 정책 (Admin 엔드포인트)

## Diff 초안

### contracts/specs/BS-01-auth/BS-01-auth.md

```diff
+## Rate Limiting 정책
+
+> **정렬 기준**:
+> - WSOP LIVE: IP whitelist(GGPass, Page 1975582764) + 비밀번호 10회 실패 자동 잠금 (Page 1972863063)
+> - OWASP API Security Top 10 #4 (Unrestricted Resource Consumption)
+> - WSOP LIVE 엔드포인트별 수치 정책 부재 → 아래 표는 EBS 독자 정의 (Why: 보안 기본값 명시 필수)
+
+### 엔드포인트 카테고리별 정책
+
+| 카테고리 | 한계치 | 범위 | 실패 응답 | 적용 엔드포인트 예시 |
+|---|---|---|---|---|
+| **인증 (로그인)** | 5회/분 + 10회 실패 자동 잠금 | per IP + per email | 429 + `Retry-After: 60` | `/auth/login`, `/auth/verify-2fa` |
+| **인증 (토큰)** | 10회/분 | per user | 429 + `Retry-After: 60` | `/auth/refresh`, `/auth/logout` |
+| **인증 (Password Reset)** | 3회/시간 | per email | 429 + `Retry-After: 3600` | `/auth/password/reset/send` |
+| **쓰기 (POST/PUT/DELETE)** | 60회/분 | per user | 429 + `Retry-After: 60` | 전체 RW 엔드포인트 |
+| **읽기 (GET)** | 300회/분 | per user | 429 + `Retry-After: 60` | 전체 R 엔드포인트 |
+| **WebSocket 메시지** | 100msg/초 | per connection | 연결 종료 + Error 이벤트 | `/ws/cc`, `/ws/lobby` |
+| **WebSocket 연결** | 10 connections | per user | 429 connection rejected | 재연결 폭주 방어 |
+| **Sync (내부)** | 동시 1 작업 | per entity_type | Skip (lock wait) | 내부 polling worker |
+
+### 응답 헤더 (표준)
+
+| 헤더 | 값 | 설명 |
+|---|---|---|
+| `X-RateLimit-Limit` | 60 | 카테고리 한계 |
+| `X-RateLimit-Remaining` | 12 | 남은 요청 수 |
+| `X-RateLimit-Reset` | 1712345678 | Unix timestamp (초) |
+| `Retry-After` | 60 | 429 응답 시만 |
+
+### 저장소 전략
+
+| Phase | 저장소 | 근거 |
+|---|---|---|
+| Phase 1 | in-memory (`slowapi` 또는 custom) | 단일 인스턴스 운영 |
+| Phase 2+ | Redis (`SET counter:{key} ... EX ...`) | 다중 인스턴스 horizontal scaling |
+
+### IP Whitelist (Admin 전용 엔드포인트)
+
+> **WSOP LIVE 패턴 준거** (GGPass External API IP whitelist).
+>
+> Phase 2+에서 적용: 특정 Admin 엔드포인트(`/users/*/suspend`, `/users/*/lock`, DB 관리 등)는
+> 사내 VPN IP 대역만 허용. 환경변수 `ADMIN_IP_WHITELIST` 로 관리.
+
+### 자동 잠금 정책 (WSOP LIVE 준거)
+
+- **비밀번호 10회 연속 실패** → `users.is_locked = true` (BS-01-auth 자동 잠금 섹션과 통합)
+- **2FA 10회 연속 실패** → 동일 Lock
+- **5분 내 토큰 refresh 50회 초과** → 의심 활동, `is_locked = true` + Admin 알림
+
+### 관측(Observability)
+
+- `rate_limit_exceeded` 이벤트 → `audit_events` 기록 (event_type, endpoint, user_id, ip, count)
+- Prometheus 메트릭 노출: `http_rate_limit_rejected_total{endpoint, reason}`
```

## Divergence from WSOP LIVE (Why)

1. **엔드포인트별 수치가 WSOP 원본 아님**: WSOP LIVE 문서 미발견. EBS 독자 정의.
   - **Why**: 보안 기본값 없이 운영 불가. OWASP + 업계 표준 기준.
2. **10회 자동 잠금만 WSOP LIVE 준거**: 명시 문서 있음(비밀번호).
3. **WSOP LIVE에 없는 WebSocket 메시지 rate limit 도입**:
   - **Why**: EBS는 실시간 오버레이가 Core. WS 채널 악성 폭주 방어 필수.

## 영향 분석

- **Team 1, 4**: 429 응답 처리 UI (friendly 메시지, Retry-After 대기). 반나절.
- **Team 2**: middleware 구현, Redis 어댑터 인터페이스(Phase 2), audit_events 연동.

## 대안 검토

1. **Rate limit 생략 (Phase 1)**: 탈락. 보안 공백.
2. **nginx 레이어에서만 처리**: 탈락. 애플리케이션 컨텍스트(user_id) 필요.
3. **모든 엔드포인트 단일 정책**: 탈락. 카테고리별 차등 필수.

## 검증

- 단위: 각 카테고리 한계치 +1 요청 → 429 + 헤더 정상
- 통합: 로그인 5회 실패 → 6번째 429, 10회 실패 → is_locked=true
- 부하: k6/Locust로 카테고리별 한계 확인
- Audit: rate_limit_exceeded 이벤트 audit_events 기록 확인

## 승인 요청

- [ ] Team 1, 4 검토 (429 UX)
- [ ] 보안 팀 (있다면) 정책 검토
- [ ] Phase 2 Redis 어댑터 설계 검토 (S3 Sprint)

## 참고 출처

| Page ID | 제목 |
|---|---|
| 1972863063 | GGPass Login (10회 실패 자동 잠금) |
| 1975582764 | GGPass External API (IP Whitelist) |
| (외부) | OWASP API Security Top 10 #4 (EBS 독자 참조) |
