# CCR-DRAFT: BS-01 refresh_token 전달 방식을 환경별 조건부로 통일

- **제안팀**: team2
- **제안일**: 2026-04-13
- **영향팀**: [team1]
- **변경 대상 파일**: contracts/specs/BS-01-auth/BS-01-auth.md, contracts/api/API-06-auth-session.md
- **변경 유형**: modify
- **변경 근거**: BS-01에서 "Refresh Token은 HttpOnly Cookie"로 정의하고 있으나, API-06 `POST /auth/login` 응답에 `refresh_token` 필드가 JSON body에 포함되어 있어 모순. WSOP LIVE Staff App API를 확인한 결과 WSOP는 HttpOnly Cookie 방식을 사용. EBS는 개발 편의와 보안의 절충을 위해 환경별 조건부 방식을 채택.

## 변경 요약

1. BS-01 §5의 "Refresh Token은 HttpOnly Cookie" 문구를 **환경별 조건부**로 변경
2. API-06 login 응답에 `refresh_token_delivery` 필드 설명 추가

## Diff 초안

BS-01:
```diff
-| **Refresh Token** | HttpOnly Cookie. 브라우저 자동 전송 |
+| **Refresh Token** | 환경별 차등 전달. dev/staging/prod: JSON body `refresh_token` 필드 / **live: HttpOnly Cookie** (`Set-Cookie: refresh_token=...; HttpOnly; Secure; SameSite=Strict; Path=/auth/refresh`) |
```

API-06 login 응답:
```diff
 | `refresh_token` | string | Refresh Token |
+| `refresh_token_delivery` | string | `"body"` 또는 `"cookie"`. live 환경에서는 `"cookie"`이며 이 필드만 응답에 포함(토큰 값은 Set-Cookie 헤더) |
```

## 영향 분석

- Team 1 (Lobby): dev/staging/prod에서 기존 JSON body 방식 유지 → 영향 없음. live 환경에서 HttpOnly Cookie로 전환 시 `credentials: 'include'` fetch 옵션 필요.
- Team 4 (CC Flutter): CC는 Secure Storage 사용이므로 Cookie 방식 영향 없음 (REST 클라이언트에서 `refresh_token` 필드 직접 저장).

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (Lobby fetch 설정)
