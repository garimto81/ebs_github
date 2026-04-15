# CCR-DRAFT: BS-01에 JWT Access/Refresh 만료 정책 명시

- **제안팀**: team2
- **제안일**: 2026-04-10
- **영향팀**: [team1]
- **변경 대상 파일**: contracts/specs/BS-01-auth/BS-01-auth.md, contracts/api/API-06-auth-session.md
- **변경 유형**: modify
- **변경 근거**: WSOP Staff App `Auth.md` 는 JWT `expires_in: 43200초(12h)` 를 운영 기준으로 사용한다. EBS의 현재 BS-01에는 "Access 15분, Refresh 7일"이 명시되어 있는데(Phase 1 초안), 14-16시간 연속 방송 시나리오에서 Access 15분은 과도한 refresh 오버헤드(방송 중 분당 4회 refresh × 운영자 N명)와 WebSocket 재연결 리스크를 유발한다. 동시에 너무 길면 토큰 탈취 시 노출 창이 커진다. 운영 환경에 맞춰 Phase별 정책을 명시적으로 정한다.

## 변경 요약

Access Token 만료를 환경별로 차등화하고, WebSocket 재연결 상호작용을 명시.

## Diff 초안

**BS-01-auth.md §5 Session**:
```diff
 ## 5. Session & Token Lifecycle
 
-- Access Token: 15분
-- Refresh Token: 7일
+### 5.1 만료 정책 (환경별)
+
+| 환경 | Access | Refresh | 근거 |
+|------|--------|---------|------|
+| dev | 1h | 24h | 개발 편의 |
+| staging | 2h | 7d | QA 테스트 세션 |
+| prod(방송 외) | 2h | 7d | 사무/관리 세션 |
+| **prod(live 방송)** | **12h** | **7d** | WSOP Staff App 준거. 14-16h 연속 방송 중 재인증 최소화 |
+
+환경 플래그는 BO 설정 `AUTH_PROFILE=dev|staging|prod|live`로 제어.
+
+### 5.2 토큰 갱신 규칙
+- 클라이언트는 Access 만료 5분 전 자동 refresh 시도
+- Refresh 실패(만료/무효) 시 즉시 로그아웃 → Lobby 로그인 화면
+- Refresh 성공 시 새 Access로 교체 (WebSocket 끊지 않음)
+
+### 5.3 WebSocket 재연결 interplay
+- WebSocket 최초 연결 시 Access 토큰 검증
+- 토큰이 연결 중 만료되면 **끊지 않고** 서버가 `token_expiring` 이벤트 발행 → 클라이언트가 refresh 후 `reauth` 커맨드 전송
+- `reauth` 미수신이 60초 경과 시 연결 종료
+
+### 5.4 강제 무효화
+- 관리자 비밀번호 변경, 역할 박탈, 수동 kick 시 Refresh Token을 DB에서 blacklist
+- Access Token은 짧은 수명으로 자연 무효화 대기 (stateless)
+- live 환경(12h)에서는 blacklist 체크가 성능 핵심 → Redis `blacklist:jti:{jti}` 캐시
```

**API-06-auth-session.md**:
```diff
 ## POST /api/v1/auth/login
 
 Response 200:
 ```json
 {
   "access_token": "...",
   "refresh_token": "...",
-  "expires_in": 900
+  "expires_in": 7200,                 // AUTH_PROFILE에 따라 3600~43200 변동
+  "expires_at": "2026-04-10T14:34:56Z",
+  "auth_profile": "prod",
+  "refresh_expires_in": 604800
 }
 ```
```

## 영향 분석

- **Team 2 (자기)**: JWT 발급 로직에 환경 플래그 분기, Redis blacklist 구현 (live 환경만), WebSocket `token_expiring` 이벤트 발행 로직. 약 6시간.
- **Team 1 (Lobby 웹)**: Zustand `authSlice`에 `expires_at` 저장, 만료 5분 전 auto-refresh 훅, `token_expiring` WebSocket 이벤트 핸들러. 약 4시간.
- **Team 4 (CC Flutter)**: Flutter secure storage에 `expires_at` 저장, 자동 refresh interceptor, WS `reauth` 커맨드. 약 4시간.
- **마이그레이션**: Phase 1 Lobby-Only Launch 패턴과 정합. 기존 15분 access 토큰 발급받은 세션은 다음 refresh 때 새 정책 적용.

## 대안 검토

1. **Access 15분 유지 + refresh 최적화** — Refresh 자체가 DB/Redis 조회 필요, 방송 12h × 운영자 8명 × 분당 4회 refresh = 23,000회/h. 부하 비현실적. 탈락.
2. **Session cookie 방식** — OAuth 제휴 시 제약, WebSocket과 조합 복잡. 탈락.
3. **환경별 프로파일 (채택)** — 보안/편의 절충, 운영 현실 반영.

## 검증 방법

- **단위**: `AUTH_PROFILE=live` 기동 시 `/auth/login` 응답 `expires_in: 43200`
- **통합**: 2시간 세션 유지 후 자동 refresh 성공, WebSocket 유지됨
- **보안**: 관리자 kick 후 30초 내 blacklist 적용, 이후 API 호출 401

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (auth auto-refresh)
- [ ] Security 검토 (live 12h 정책 적절성)
