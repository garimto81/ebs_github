# 통합 테스트

> Conductor 소유. 팀 간 API 계약을 HTTP/WebSocket 호출로 검증.

## 규칙

- **소스 임포트 금지** — 다른 팀 폴더의 소스를 직접 import하지 않음
- **HTTP/WebSocket only** — 각 팀의 서비스 엔드포인트를 호출
- 테스트 시나리오는 `.http` 형식 (REST Client 호환)
- 계약 문서 위치: `../contracts/api/`
- 이 폴더는 통합 테스트 전용 Conductor 세션 영역입니다.

## 서비스 엔드포인트

| 서비스 | 포트 | 팀 |
|--------|------|-----|
| Backend (BO) | http://localhost:8000 | Team 2 |
| Engine Harness | http://localhost:8080 | Team 3 |
| WebSocket (Lobby) | ws://localhost:8000/ws/lobby | Team 2 |
| WebSocket (CC) | ws://localhost:8000/ws/cc | Team 2 |
