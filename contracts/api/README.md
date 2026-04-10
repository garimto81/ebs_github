# API 계약 문서 — 네비게이션

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | API 문서 4종 네비게이션 |
| 2026-04-08 | 문서 추가 | API-01, API-02, API-04 추가 (총 6종) |

---

## 개요

이 폴더는 EBS 3-앱 아키텍처(Lobby ↔ BO ↔ CC)의 **API 계약 문서**를 관리한다. 각 문서는 앱 간 통신 인터페이스의 단일 출처(Single Source of Truth)다.

## 문서 목록

| 문서 | 파일 | 핵심 내용 |
|------|------|----------|
| **Backend Endpoints** | `API-01-backend-endpoints.md` | BO REST API 전체 카탈로그 (66개 엔드포인트), 공통 응답 포맷, 페이지네이션 |
| **WSOP LIVE Integration** | `API-02-wsop-live-integration.md` | WSOP LIVE API 폴링 연동, 데이터 매핑, 충돌 해결, Mock 모드, 장애 대응 |
| **RFID HAL Interface** | `API-03-rfid-hal-interface.md` | IRfidReader 추상 인터페이스, Real/Mock HAL 교체 계약, 이벤트 타입, DI 메커니즘 |
| **Overlay Output** | `API-04-overlay-output.md` | CC→Overlay 데이터 흐름, NDI/HDMI/크로마키 출력, Security Delay, 해상도 |
| **WebSocket Events** | `API-05-websocket-events.md` | CC ↔ BO ↔ Lobby 간 WebSocket 이벤트 프로토콜, 메시지 포맷, 연결 생명주기 |
| **Auth & Session** | `API-06-auth-session.md` | JWT 인증, 토큰 관리, 세션 API, RBAC 매트릭스 |

## 참조 관계

```
BS-00-definitions.md ─── 용어/상태/트리거 정의
        │
        ├── API-01 ← BO-01-overview.md (BO API 분류)
        ├── API-02 ← BS-02-lobby.md (WSOP LIVE 연동)
        ├── API-03 ← BS-04-rfid/ (행동 명세)
        ├── API-04 ← BS-07-overlay/ (오버레이 행동 명세)
        ├── API-05 ← BS-06-00-triggers.md (이벤트 카탈로그)
        └── API-06 ← BS-01-auth/ (인증 행동 명세)
```

## 규약

- 모든 API 문서는 WSOP LIVE Confluence 문서 표준을 따른다
- Dart 코드 블록은 `dart` 언어 지정
- Enum 값 상세는 `BS-06-00-REF-game-engine-spec.md` 참조
- 용어 정의는 `BS-00-definitions.md` 참조
