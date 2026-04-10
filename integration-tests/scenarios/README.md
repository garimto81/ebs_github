# Integration Test Scenarios

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | CCR-010~036 계약 검증 시나리오 카탈로그 |

---

## 파일명 체계

```
{그룹번호}-{주제}.http
```

| 그룹 | 범위 | 커버 CCR |
|:----:|------|----------|
| **10~19** | Auth / Idempotency / Saga / WS Replay | 010, 019, 020, 021, 018 |
| **20~29** | Graphic Editor (API-07) + DATA-07 + skin_updated | 011, 012, 013, 014, 015 |
| **30~39** | CC Launch / BO Recovery / WriteGameInfo / Statistics | 027, 029, 031, 024 |
| **40~49** | Overlay / Security Delay / Color sync | 025, 033, 034, 036 |
| **50~59** | RFID / Deck Register | 022, 026 |
| **60~69** | team1 WSOP Parity (Event/Flight/Table/RBAC) | 016, 017 |

## 실행 환경

- **VSCode REST Client** 또는 **httpyac** 확장
- Backend BO 서비스(`http://localhost:8000`) 실행 중이어야 함
- 일부 WebSocket 시나리오는 별도 `wscat`/`websocat` CLI 필요

## 공통 설정

`_env.http` 참조 — host, 인증 토큰, 테스트 ID 정의.

환경 변수(`.env`)로 token 주입:
```
ADMIN_JWT=eyJhbGc...
OPERATOR_JWT=eyJhbGc...
VIEWER_JWT=eyJhbGc...
```

## CCR 추적

각 시나리오 파일 상단에 커버하는 CCR 번호를 명시한다. 예: `### CCR-013 §1 POST /skins — Upload`.

미작성 시나리오는 `_TODO.md` 참조.
