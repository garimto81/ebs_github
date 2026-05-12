# Cycle 9 QA Real — Lobby Login Evidence

Run timestamp: 2026-05-12T10:36:28.223Z
Lobby base URL: http://localhost:3000

## Result
- Entry URL: http://localhost:3000/?enable-semantics-on-app-start=true#/login?redirect=/lobby
- After URL: http://localhost:3000/?enable-semantics-on-app-start=true#/lobby/series
- URL changed: true
- Token in localStorage: false
- Auth 200 calls: 1
- Login DoD: PASS
- Input strategy: canvas-coordinate
- Submit strategy: canvas-coordinate

## Network log
- POST http://api.ebs.local/api/v1/auth/login → 200
- GET http://api.ebs.local/api/v1/auth/session → 200
- GET http://api.ebs.local/api/v1/series → 200

## Screenshot evidence
- 01-lobby-load.png       — Flutter 부트 직후
- 02-login-form.png       — login UI 노출
- 03-credentials-typed.png — admin@local 입력 완료
- 04-login-submitted.png  — Log In 클릭 직후
- 05-after-auth.png       — BO /auth/login 응답 후
- 06-dashboard.png        — 최종 화면
