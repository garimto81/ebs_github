---
id: B-027
title: Google OAuth 2.0 추가
status: DONE
source: docs/2. Development/2.2 Backend/Backlog.md
---

# [B-027] Google OAuth 2.0 추가
- **날짜**: 2026-04-09
- **완료일**: 2026-04-16
- **teams**: [team2]
- **설명**: `GET /auth/google`, `GET /auth/google/callback`. 기존 Email+2FA에 Google OAuth 옵션 추가.
- **수락 기준**: Google 계정으로 로그인 → JWT 발급 성공.
- **구현 방식**: Mock Provider (dev/staging). `GOOGLE_CLIENT_ID` 환경 변수 설정 시 실제 전환.
- **관련 커밋**: auth.py, auth_service.py Google OAuth mock 엔드포인트 추가
